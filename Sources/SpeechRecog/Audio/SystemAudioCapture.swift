import AudioToolbox
import CoreAudio
import Foundation

/// Captures system-wide output audio non-destructively using a Core Audio
/// Process Tap attached to a private Aggregate Device, then writes M4A (AAC).
///
/// - The tap is global (every process) but excludes our own PID so we never
///   record our own UI sounds.
/// - The aggregate device is private (not visible in System Settings) and
///   uses the current default output device as its main sub-device, so the
///   user keeps hearing audio normally while we record from the tap.
/// - Requires macOS 14.2+.
final class SystemAudioCapture {

    private let outputURL: URL

    private var tapID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    private var aggregateID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    private var ioProcID: AudioDeviceIOProcID?

    private var fileRef: ExtAudioFileRef?
    private let ioQueue = DispatchQueue(label: "es.speechrecog.audio.io", qos: .userInitiated)

    init(outputURL: URL) {
        self.outputURL = outputURL
    }

    func start() throws {
        let (tapID, tapUID) = try createProcessTap()
        self.tapID = tapID

        let tapFormat = try fetchTapFormat(tapID: tapID)

        let outputUID = try CoreAudio.defaultOutputDeviceUID()
        let aggregateID = try createAggregateDevice(outputUID: outputUID, tapUID: tapUID)
        self.aggregateID = aggregateID

        try openOutputFile(clientFormat: tapFormat)
        try installIOProc(on: aggregateID)

        try CoreAudio.check(AudioDeviceStart(aggregateID, ioProcID), "AudioDeviceStart")
    }

    func stop() throws {
        if aggregateID != kAudioObjectUnknown, let procID = ioProcID {
            AudioDeviceStop(aggregateID, procID)
            AudioDeviceDestroyIOProcID(aggregateID, procID)
        }
        ioProcID = nil

        if aggregateID != kAudioObjectUnknown {
            AudioHardwareDestroyAggregateDevice(aggregateID)
            aggregateID = AudioObjectID(kAudioObjectUnknown)
        }
        if tapID != kAudioObjectUnknown {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = AudioObjectID(kAudioObjectUnknown)
        }

        ioQueue.sync {
            if let fileRef {
                ExtAudioFileDispose(fileRef)
            }
            self.fileRef = nil
        }
    }

    // MARK: - Tap creation

    private func createProcessTap() throws -> (id: AudioObjectID, uid: String) {
        let ownProcessObject = try CoreAudio.translatePIDToProcessObject(getpid())

        let description = CATapDescription(
            stereoGlobalTapButExcludeProcesses: [NSNumber(value: ownProcessObject)]
        )
        let tapUUID = UUID()
        description.uuid = tapUUID
        description.name = "SpeechRecog Tap"
        description.isPrivate = true

        var tapID = AudioObjectID(kAudioObjectUnknown)
        try CoreAudio.check(AudioHardwareCreateProcessTap(description, &tapID), "CreateProcessTap")
        return (tapID, tapUUID.uuidString)
    }

    private func fetchTapFormat(tapID: AudioObjectID) throws -> AudioStreamBasicDescription {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioTapPropertyFormat,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var asbd = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        try CoreAudio.check(
            AudioObjectGetPropertyData(tapID, &addr, 0, nil, &size, &asbd),
            "TapFormat"
        )
        return asbd
    }

    // MARK: - Aggregate device

    private func createAggregateDevice(outputUID: String, tapUID: String) throws -> AudioObjectID {
        let aggregateUID = "es.speechrecog.aggregate.\(UUID().uuidString)"
        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey as String: "SpeechRecog Aggregate",
            kAudioAggregateDeviceUIDKey as String: aggregateUID,
            kAudioAggregateDeviceMainSubDeviceKey as String: outputUID,
            kAudioAggregateDeviceIsPrivateKey as String: true,
            kAudioAggregateDeviceIsStackedKey as String: false,
            kAudioAggregateDeviceTapAutoStartKey as String: true,
            kAudioAggregateDeviceTapListKey as String: [
                [
                    kAudioSubTapUIDKey as String: tapUID,
                    kAudioSubTapDriftCompensationKey as String: true
                ]
            ],
            kAudioAggregateDeviceSubDeviceListKey as String: [
                [kAudioSubDeviceUIDKey as String: outputUID]
            ]
        ]
        var aggregateID = AudioObjectID(kAudioObjectUnknown)
        try CoreAudio.check(
            AudioHardwareCreateAggregateDevice(description as CFDictionary, &aggregateID),
            "CreateAggregateDevice"
        )
        return aggregateID
    }

    // MARK: - File output

    private func openOutputFile(clientFormat: AudioStreamBasicDescription) throws {
        var clientFormat = clientFormat
        let channels = max(1, clientFormat.mChannelsPerFrame)
        let sampleRate = clientFormat.mSampleRate > 0 ? clientFormat.mSampleRate : 48_000

        var fileFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatMPEG4AAC,
            mFormatFlags: 0,
            mBytesPerPacket: 0,
            mFramesPerPacket: 1024,
            mBytesPerFrame: 0,
            mChannelsPerFrame: channels,
            mBitsPerChannel: 0,
            mReserved: 0
        )

        var newFileRef: ExtAudioFileRef?
        try CoreAudio.check(
            ExtAudioFileCreateWithURL(
                outputURL as CFURL,
                kAudioFileM4AType,
                &fileFormat,
                nil,
                AudioFileFlags.eraseFile.rawValue,
                &newFileRef
            ),
            "ExtAudioFileCreate"
        )
        guard let newFileRef else { throw CoreAudioError.unsupportedFormat }

        try CoreAudio.check(
            ExtAudioFileSetProperty(
                newFileRef,
                kExtAudioFileProperty_ClientDataFormat,
                UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                &clientFormat
            ),
            "Set ClientDataFormat"
        )

        // Prime the async writer thread; safe to call from a non-realtime context.
        var nullList = AudioBufferList()
        _ = ExtAudioFileWriteAsync(newFileRef, 0, &nullList)

        self.fileRef = newFileRef
    }

    // MARK: - IOProc

    private func installIOProc(on aggregate: AudioObjectID) throws {
        let block: AudioDeviceIOBlock = { [weak self] _, inputData, _, _, _ in
            guard let self else { return }
            guard let fileRef = self.fileRef else { return }

            let bufferList = inputData
            let buffersCount = Int(bufferList.pointee.mNumberBuffers)
            guard buffersCount > 0 else { return }

            let firstBuffer = bufferList.pointee.mBuffers
            let bytesPerFramePerChannel = UInt32(MemoryLayout<Float32>.size)
            // For interleaved (1 buffer): frame size = bytesPerFrame * channels
            // For non-interleaved (N buffers, 1 ch each): same buffer holds 1 channel
            let channelsInFirstBuffer = max(UInt32(1), firstBuffer.mNumberChannels)
            let perFrameBytes = bytesPerFramePerChannel * channelsInFirstBuffer
            guard perFrameBytes > 0 else { return }
            let frames = firstBuffer.mDataByteSize / perFrameBytes
            guard frames > 0 else { return }

            let status = ExtAudioFileWriteAsync(fileRef, frames, bufferList)
            if status != noErr {
                NSLog("[SpeechRecog] ExtAudioFileWriteAsync error: \(status)")
            }
        }

        var procID: AudioDeviceIOProcID?
        try CoreAudio.check(
            AudioDeviceCreateIOProcIDWithBlock(&procID, aggregate, ioQueue, block),
            "CreateIOProcWithBlock"
        )
        self.ioProcID = procID
    }

}

import AudioToolbox
import CoreAudio
import Foundation

/// Captures system-wide output audio via a Core Audio Process Tap + Aggregate Device.
/// Optionally mixes in microphone audio. Writes the result to an M4A (AAC) file.
///
/// Requires macOS 14.2+.
final class SystemAudioCapture {

    // MARK: - Configuration

    private let outputURL: URL
    private let micCapture: MicrophoneCapture?
    private let micGain: Float = 4.0

    // MARK: - Core Audio objects

    private var tapID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    private var aggregateID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    private var ioProcID: AudioDeviceIOProcID?

    // MARK: - File writer

    private var fileRef: ExtAudioFileRef?
    private let ioQueue = DispatchQueue(label: "es.speechrecog.audio.io", qos: .userInitiated)

    // MARK: - Mixing buffers (allocated only when mic is active)

    private var mixBuffer: UnsafeMutablePointer<Float>?
    private var mixCapacity: Int = 0
    private var outBuffer: UnsafeMutablePointer<UInt8>?

    /// Called from the IO thread with the peak level (0.0-1.0).
    var onLevel: ((Float) -> Void)?

    init(outputURL: URL, micCapture: MicrophoneCapture? = nil) {
        self.outputURL = outputURL
        self.micCapture = micCapture
    }

    // MARK: - Lifecycle

    func start() throws {
        // 1. Create tap and aggregate device
        let (tapID, tapUID) = try createProcessTap()
        self.tapID = tapID

        let outputDeviceID = try CoreAudio.defaultOutputDeviceID()
        let outputUID = try CoreAudio.defaultOutputDeviceUID()
        let aggregateID = try createAggregateDevice(outputUID: outputUID, tapUID: tapUID)
        self.aggregateID = aggregateID

        // 2. The aggregate device reports format metadata (channels, layout, etc.)
        //    but its sample rate may not match the actual IOProc delivery rate.
        //    The output device's nominal rate is the ground truth.
        var recordingFormat = try CoreAudio.deviceInputStreamFormat(aggregateID)
        let outputDeviceRate = try CoreAudio.deviceNominalSampleRate(outputDeviceID)

        NSLog("[SpeechRecog] Aggregate format: %.0f Hz, %d ch — Output device rate: %.0f Hz",
              recordingFormat.mSampleRate, recordingFormat.mChannelsPerFrame, outputDeviceRate)

        if outputDeviceRate > 0 {
            recordingFormat.mSampleRate = outputDeviceRate
        }

        // 3. Start mic at the same rate as the aggregate device
        if let mic = micCapture {
            do {
                try mic.start(targetSampleRate: recordingFormat.mSampleRate)
            } catch {
                NSLog("[SpeechRecog] Mic unavailable, continuing without: %@", "\(error)")
            }
            allocateMixBuffers(format: recordingFormat)
        }

        // 4. Open output file and start IO
        try openOutputFile(clientFormat: recordingFormat)
        try installIOProc(on: aggregateID)
        try CoreAudio.check(AudioDeviceStart(aggregateID, ioProcID), "AudioDeviceStart")

        NSLog("[SpeechRecog] Recording started")
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
            if let fileRef { ExtAudioFileDispose(fileRef) }
            self.fileRef = nil
        }

        deallocateMixBuffers()
    }

    // MARK: - Process Tap

    private func createProcessTap() throws -> (id: AudioObjectID, uid: String) {
        let ownProcess = try CoreAudio.translatePIDToProcessObject(getpid())
        let description = CATapDescription(stereoGlobalTapButExcludeProcesses: [ownProcess])
        let uuid = UUID()
        description.uuid = uuid
        description.name = "SpeechRecog Tap"
        description.isPrivate = true

        var tapID = AudioObjectID(kAudioObjectUnknown)
        try CoreAudio.check(AudioHardwareCreateProcessTap(description, &tapID), "CreateProcessTap")
        return (tapID, uuid.uuidString)
    }

    // MARK: - Aggregate Device

    private func createAggregateDevice(outputUID: String, tapUID: String) throws -> AudioObjectID {
        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey as String: "SpeechRecog Aggregate",
            kAudioAggregateDeviceUIDKey as String: "es.speechrecog.aggregate.\(UUID().uuidString)",
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

    // MARK: - File Output

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

        var ref: ExtAudioFileRef?
        try CoreAudio.check(
            ExtAudioFileCreateWithURL(
                outputURL as CFURL, kAudioFileM4AType, &fileFormat,
                nil, AudioFileFlags.eraseFile.rawValue, &ref
            ),
            "ExtAudioFileCreate"
        )
        guard let ref else { throw CoreAudioError.unsupportedFormat }

        try CoreAudio.check(
            ExtAudioFileSetProperty(
                ref, kExtAudioFileProperty_ClientDataFormat,
                UInt32(MemoryLayout<AudioStreamBasicDescription>.size), &clientFormat
            ),
            "SetClientDataFormat"
        )

        var nullList = AudioBufferList()
        _ = ExtAudioFileWriteAsync(ref, 0, &nullList)
        self.fileRef = ref
    }

    // MARK: - Mix Buffers

    private func allocateMixBuffers(format: AudioStreamBasicDescription) {
        let maxFrames = 4096
        mixCapacity = maxFrames
        mixBuffer = .allocate(capacity: maxFrames)
        let outSize = maxFrames * Int(format.mBytesPerFrame) + MemoryLayout<AudioBufferList>.size
        outBuffer = .allocate(capacity: outSize)
    }

    private func deallocateMixBuffers() {
        mixBuffer?.deallocate()
        mixBuffer = nil
        mixCapacity = 0
        outBuffer?.deallocate()
        outBuffer = nil
    }

    // MARK: - IOProc

    private func installIOProc(on aggregate: AudioObjectID) throws {
        let block: AudioDeviceIOBlock = { [weak self] _, inputData, _, _, _ in
            guard let self, let fileRef = self.fileRef else { return }

            let srcBuf = inputData.pointee.mBuffers
            guard inputData.pointee.mNumberBuffers > 0,
                  let srcData = srcBuf.mData,
                  srcBuf.mDataByteSize > 0 else { return }

            let bytesPerSample = UInt32(MemoryLayout<Float32>.size)
            let channels = max(UInt32(1), srcBuf.mNumberChannels)
            let frames = srcBuf.mDataByteSize / (bytesPerSample * channels)
            guard frames > 0 else { return }

            let writePtr: UnsafePointer<AudioBufferList>

            if let mic = self.micCapture, let mixBuf = self.mixBuffer, let outBuf = self.outBuffer {
                writePtr = self.mixMicInto(
                    inputData: inputData, srcData: srcData, dataSize: Int(srcBuf.mDataByteSize),
                    frames: Int(frames), channels: Int(channels),
                    mic: mic, mixBuf: mixBuf, outBuf: outBuf
                )
            } else {
                writePtr = inputData
            }

            self.reportLevel(from: writePtr, bytesPerSample: bytesPerSample)

            let status = ExtAudioFileWriteAsync(fileRef, frames, writePtr)
            if status != noErr {
                NSLog("[SpeechRecog] ExtAudioFileWriteAsync error: %d", status)
            }
        }

        var procID: AudioDeviceIOProcID?
        try CoreAudio.check(
            AudioDeviceCreateIOProcIDWithBlock(&procID, aggregate, ioQueue, block),
            "CreateIOProcWithBlock"
        )
        self.ioProcID = procID
    }

    // MARK: - Mic Mixing (called from IOProc, must be real-time safe)

    private func mixMicInto(
        inputData: UnsafePointer<AudioBufferList>,
        srcData: UnsafeMutableRawPointer,
        dataSize: Int,
        frames: Int,
        channels: Int,
        mic: MicrophoneCapture,
        mixBuf: UnsafeMutablePointer<Float>,
        outBuf: UnsafeMutablePointer<UInt8>
    ) -> UnsafePointer<AudioBufferList> {
        let ablSize = MemoryLayout<AudioBufferList>.size
        memcpy(outBuf, inputData, ablSize)
        let outABL = UnsafeMutableRawPointer(outBuf).assumingMemoryBound(to: AudioBufferList.self)
        let audioDataDst = outBuf.advanced(by: ablSize)
        memcpy(audioDataDst, srcData, dataSize)
        outABL.pointee.mBuffers.mData = UnsafeMutableRawPointer(audioDataDst)

        let toRead = min(frames, mixCapacity)
        let micRead = mic.ringBuffer.read(into: mixBuf, count: toRead)

        if micRead > 0 {
            let dst = UnsafeMutableRawPointer(audioDataDst).assumingMemoryBound(to: Float.self)
            let gain = self.micGain
            for f in 0..<min(frames, micRead) {
                let sample = mixBuf[f] * gain
                for c in 0..<channels {
                    dst[f * channels + c] += sample
                }
            }
        }

        return UnsafePointer(outABL)
    }

    // MARK: - Level Metering

    private func reportLevel(from bufferList: UnsafePointer<AudioBufferList>, bytesPerSample: UInt32) {
        guard let onLevel else { return }
        let buf = bufferList.pointee.mBuffers
        guard let data = buf.mData?.assumingMemoryBound(to: Float.self) else { return }
        var peak: Float = 0
        let count = Int(buf.mDataByteSize / bytesPerSample)
        for i in 0..<count {
            let a = Swift.abs(data[i])
            if a > peak { peak = a }
        }
        onLevel(min(peak, 1.0))
    }
}

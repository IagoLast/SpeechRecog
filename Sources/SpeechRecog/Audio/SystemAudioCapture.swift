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

    private var writeError: OSStatus = noErr
    private var mixer: AudioMixer?
    private var framesSinceLevelUpdate = 0
    private var levelUpdateInterval = 4800
    private var peakLevel: Float = 0

    /// Called from the IO thread with the peak level (0.0-1.0).
    var onLevel: ((Float) -> Void)?

    init(outputURL: URL, micCapture: MicrophoneCapture? = nil) {
        self.outputURL = outputURL
        self.micCapture = micCapture
    }

    // MARK: - Lifecycle

    deinit {
        try? stop()
    }

    func start() throws {
        var started = false
        defer {
            if !started {
                let createdOutput = fileRef != nil
                try? stop()
                if createdOutput { try? FileManager.default.removeItem(at: outputURL) }
            }
        }

        // 1. Create tap and aggregate device
        let (tapID, tapUID) = try createProcessTap()
        self.tapID = tapID

        let outputDeviceID = try CoreAudio.defaultOutputDeviceID()
        let outputUID = try CoreAudio.deviceUID(outputDeviceID)
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

        guard recordingFormat.mFormatID == kAudioFormatLinearPCM,
              recordingFormat.mFormatFlags & kAudioFormatFlagIsFloat != 0,
              recordingFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved == 0,
              recordingFormat.mBitsPerChannel == 32,
              recordingFormat.mChannelsPerFrame > 0,
              recordingFormat.mBytesPerFrame == recordingFormat.mChannelsPerFrame * 4,
              recordingFormat.mSampleRate.isFinite, recordingFormat.mSampleRate > 0 else {
            throw CoreAudioError.unsupportedFormat
        }
        levelUpdateInterval = max(1, Int(recordingFormat.mSampleRate / 10))

        // 3. Start mic at the same rate as the aggregate device
        if let mic = micCapture {
            do {
                try mic.start(targetSampleRate: recordingFormat.mSampleRate)
                mixer = AudioMixer(channels: Int(recordingFormat.mChannelsPerFrame))
            } catch {
                NSLog("[SpeechRecog] Mic unavailable, continuing without: %@", "\(error)")
            }
        }

        // 4. Open output file and start IO
        try openOutputFile(clientFormat: recordingFormat)
        try installIOProc(on: aggregateID)
        // Core Audio requests system audio recording access on first use.
        // Screen capture access is a separate permission and is not needed here.
        try CoreAudio.check(AudioDeviceStart(aggregateID, ioProcID), "AudioDeviceStart")

        started = true
        NSLog("[SpeechRecog] Recording started")
    }

    func stop() throws {
        var firstError: Error?
        func check(_ status: OSStatus, _ operation: String) {
            if status != noErr, firstError == nil {
                firstError = CoreAudioError.osStatus(operation, status)
            }
        }
        if aggregateID != kAudioObjectUnknown, let procID = ioProcID {
            check(AudioDeviceStop(aggregateID, procID), "AudioDeviceStop")
            check(AudioDeviceDestroyIOProcID(aggregateID, procID), "DestroyIOProc")
        }
        ioProcID = nil

        if aggregateID != kAudioObjectUnknown {
            check(AudioHardwareDestroyAggregateDevice(aggregateID), "DestroyAggregateDevice")
            aggregateID = AudioObjectID(kAudioObjectUnknown)
        }
        if tapID != kAudioObjectUnknown {
            check(AudioHardwareDestroyProcessTap(tapID), "DestroyProcessTap")
            tapID = AudioObjectID(kAudioObjectUnknown)
        }

        ioQueue.sync {
            check(writeError, "WriteAudio")
            writeError = noErr
            if let fileRef { check(ExtAudioFileDispose(fileRef), "CloseAudioFile") }
            self.fileRef = nil
        }

        micCapture?.stop()
        mixer = nil
        framesSinceLevelUpdate = 0
        peakLevel = 0
        if let firstError { throw firstError }
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
                nil, 0, &ref
            ),
            "ExtAudioFileCreate"
        )
        guard let ref else { throw CoreAudioError.unsupportedFormat }
        self.fileRef = ref

        try CoreAudio.check(
            ExtAudioFileSetProperty(
                ref, kExtAudioFileProperty_ClientDataFormat,
                UInt32(MemoryLayout<AudioStreamBasicDescription>.size), &clientFormat
            ),
            "SetClientDataFormat"
        )

        var nullList = AudioBufferList()
        try CoreAudio.check(ExtAudioFileWriteAsync(ref, 0, &nullList), "PrepareAudioWriter")
    }

    // MARK: - IOProc

    private func installIOProc(on aggregate: AudioObjectID) throws {
        let block: AudioDeviceIOBlock = { [weak self] _, inputData, _, _, _ in
            guard let self, self.fileRef != nil, self.writeError == noErr else { return }
            guard inputData.pointee.mNumberBuffers == 1 else {
                self.writeError = kAudioFileUnsupportedDataFormatError
                return
            }
            let buffer = inputData.pointee.mBuffers
            guard let samples = buffer.mData?.assumingMemoryBound(to: Float.self),
                  buffer.mNumberChannels > 0 else { return }
            let channels = Int(buffer.mNumberChannels)
            let frames = Int(buffer.mDataByteSize) / (MemoryLayout<Float>.size * channels)
            guard frames > 0 else { return }

            if let mixer = self.mixer, let mic = self.micCapture {
                guard mixer.channels == channels else {
                    self.writeError = kAudioFileUnsupportedDataFormatError
                    return
                }
                mixer.process(input: samples, frameCount: frames, microphone: mic.ringBuffer, gain: self.micGain) {
                    self.writeAudio($0, frames: $1, channels: channels)
                }
            } else {
                self.writeAudio(samples, frames: frames, channels: channels)
            }
        }

        var procID: AudioDeviceIOProcID?
        try CoreAudio.check(
            AudioDeviceCreateIOProcIDWithBlock(&procID, aggregate, ioQueue, block),
            "CreateIOProcWithBlock"
        )
        ioProcID = procID
    }

    private func writeAudio(_ samples: UnsafePointer<Float>, frames: Int, channels: Int) {
        guard let fileRef, writeError == noErr else { return }
        var buffers = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: UInt32(channels),
                mDataByteSize: UInt32(frames * channels * MemoryLayout<Float>.size),
                mData: UnsafeMutableRawPointer(mutating: samples)
            )
        )
        // Record the first failure and report it when stopping, off the audio thread.
        writeError = ExtAudioFileWriteAsync(fileRef, UInt32(frames), &buffers)

        for index in 0..<(frames * channels) {
            peakLevel = max(peakLevel, abs(samples[index]))
        }
        framesSinceLevelUpdate += frames
        if framesSinceLevelUpdate >= levelUpdateInterval {
            onLevel?(min(peakLevel, 1))
            framesSinceLevelUpdate = 0
            peakLevel = 0
        }
    }
}

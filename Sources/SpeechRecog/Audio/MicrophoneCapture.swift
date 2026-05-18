import AVFoundation

/// Captures audio from the default input device (microphone) into a ring buffer
/// that can be read from a real-time audio thread.
///
/// Samples are written to the ring buffer as mono Float32 at the hardware's
/// native sample rate. The consumer is responsible for matching rates.
final class MicrophoneCapture {
    private let engine = AVAudioEngine()
    let ringBuffer: AudioRingBuffer
    private(set) var sampleRate: Double = 0
    private(set) var channels: UInt32 = 0

    init() {
        self.ringBuffer = AudioRingBuffer(capacity: 48_000 * 2)
    }

    func start(targetSampleRate: Double? = nil) throws {
        let inputNode = engine.inputNode
        let hwFormat = inputNode.inputFormat(forBus: 0)
        guard hwFormat.sampleRate > 0, hwFormat.channelCount > 0 else {
            throw MicrophoneCaptureError.noInputDevice
        }

        let outputRate = targetSampleRate ?? hwFormat.sampleRate
        self.sampleRate = outputRate
        self.channels = 1

        // Tap must use hardware sample rate; we downmix to mono here.
        let monoHwFormat = AVAudioFormat(standardFormatWithSampleRate: hwFormat.sampleRate, channels: 1)!

        // Resample from hw rate to target rate if they differ.
        var converter: AVAudioConverter?
        if outputRate != hwFormat.sampleRate,
           let outFormat = AVAudioFormat(standardFormatWithSampleRate: outputRate, channels: 1) {
            converter = AVAudioConverter(from: monoHwFormat, to: outFormat)
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: monoHwFormat) { [weak self] pcmBuffer, _ in
            guard let self else { return }

            if let converter {
                let ratio = outputRate / hwFormat.sampleRate
                let outFrames = AVAudioFrameCount(ceil(Double(pcmBuffer.frameLength) * ratio))
                guard let outBuf = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: outFrames) else { return }
                var consumedInput = false
                let status = converter.convert(to: outBuf, error: nil) { _, outStatus in
                    if consumedInput {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    consumedInput = true
                    outStatus.pointee = .haveData
                    return pcmBuffer
                }
                if status != .error, let data = outBuf.floatChannelData, outBuf.frameLength > 0 {
                    self.ringBuffer.write(from: data[0], count: Int(outBuf.frameLength))
                }
            } else {
                guard let floatData = pcmBuffer.floatChannelData else { return }
                self.ringBuffer.write(from: floatData[0], count: Int(pcmBuffer.frameLength))
            }
        }

        try engine.start()
        NSLog("[SpeechRecog] Mic started: hw=%.0f Hz → output=%.0f Hz, mono", hwFormat.sampleRate, outputRate)
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}

enum MicrophoneCaptureError: LocalizedError {
    case noInputDevice

    var errorDescription: String? {
        switch self {
        case .noInputDevice:
            return "No se encontró un dispositivo de entrada de audio (micrófono)"
        }
    }
}

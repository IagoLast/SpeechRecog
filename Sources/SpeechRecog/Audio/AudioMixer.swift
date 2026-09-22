/// Reusable storage for interleaved Float32 audio. Large callbacks are processed
/// in bounded chunks, so the audio thread never allocates or overruns a buffer.
final class AudioMixer {
    let frameCapacity: Int
    let channels: Int
    private let microphoneSamples: UnsafeMutablePointer<Float>
    private let output: UnsafeMutablePointer<Float>

    init(channels: Int, frameCapacity: Int = 4096) {
        precondition(channels > 0 && frameCapacity > 0)
        self.channels = channels
        self.frameCapacity = frameCapacity
        microphoneSamples = .allocate(capacity: frameCapacity)
        microphoneSamples.initialize(repeating: 0, count: frameCapacity)
        output = .allocate(capacity: frameCapacity * channels)
        output.initialize(repeating: 0, count: frameCapacity * channels)
    }

    deinit {
        microphoneSamples.deallocate()
        output.deallocate()
    }

    func process(
        input: UnsafePointer<Float>,
        frameCount: Int,
        microphone: AudioRingBuffer,
        gain: Float,
        write: (UnsafePointer<Float>, Int) -> Void
    ) {
        var offset = 0
        while offset < frameCount {
            let frames = min(frameCapacity, frameCount - offset)
            output.update(from: input.advanced(by: offset * channels), count: frames * channels)
            let microphoneFrames = microphone.read(into: microphoneSamples, count: frames)
            for frame in 0..<microphoneFrames {
                let sample = microphoneSamples[frame] * gain
                for channel in 0..<channels {
                    let index = frame * channels + channel
                    output[index] = max(-1, min(1, output[index] + sample))
                }
            }
            write(UnsafePointer(output), frames)
            offset += frames
        }
    }
}

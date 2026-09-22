import XCTest
@testable import SpeechRecog

final class AudioMixerTests: XCTestCase {
    func testLargeCallbackMixesEveryFrameWithoutExceedingCapacity() {
        let frames = 9001
        let mixer = AudioMixer(channels: 2)
        let microphone = AudioRingBuffer(capacity: frames)
        let micSamples = [Float](repeating: 0.2, count: frames)
        _ = micSamples.withUnsafeBufferPointer {
            microphone.write(from: $0.baseAddress!, count: $0.count)
        }
        let input = [Float](repeating: 0.05, count: frames * 2)
        var output = [Float]()
        var chunks = [Int]()
        input.withUnsafeBufferPointer {
            mixer.process(input: $0.baseAddress!, frameCount: frames, microphone: microphone, gain: 1) { samples, count in
                XCTAssertLessThanOrEqual(count, mixer.frameCapacity)
                chunks.append(count)
                output.append(contentsOf: UnsafeBufferPointer(start: samples, count: count * 2))
            }
        }
        XCTAssertEqual(chunks.reduce(0, +), frames)
        XCTAssertEqual(output, [Float](repeating: 0.25, count: frames * 2))
    }

    func testMicrophoneUnderflowPreservesSystemAudioWithoutReusingOldSamples() {
        let mixer = AudioMixer(channels: 2, frameCapacity: 2)
        let microphone = AudioRingBuffer(capacity: 4)
        let micSamples: [Float] = [0.5]
        _ = micSamples.withUnsafeBufferPointer { microphone.write(from: $0.baseAddress!, count: 1) }
        let input: [Float] = [0.75, -0.75, 0.1, -0.1, 0.2, -0.2]
        var output = [Float]()
        input.withUnsafeBufferPointer {
            mixer.process(input: $0.baseAddress!, frameCount: 3, microphone: microphone, gain: 1) { samples, count in
                output.append(contentsOf: UnsafeBufferPointer(start: samples, count: count * 2))
            }
        }
        XCTAssertEqual(output, [1, -0.25, 0.1, -0.1, 0.2, -0.2])
    }

    func testMixingClampsBothPositiveAndNegativePeaks() {
        let mixer = AudioMixer(channels: 1)
        let microphone = AudioRingBuffer(capacity: 2)
        let micSamples: [Float] = [0.5, -0.5]
        _ = micSamples.withUnsafeBufferPointer { microphone.write(from: $0.baseAddress!, count: 2) }
        let input: [Float] = [0.5, -0.5]
        input.withUnsafeBufferPointer {
            mixer.process(input: $0.baseAddress!, frameCount: 2, microphone: microphone, gain: 4) { samples, count in
                XCTAssertEqual(Array(UnsafeBufferPointer(start: samples, count: count)), [1, -1])
            }
        }
    }
}

import XCTest
@testable import SpeechRecog

final class AudioRingBufferTests: XCTestCase {
    func testFullBufferPreservesUnreadAudioAndAcceptsNewAudioAfterReading() {
        let ring = AudioRingBuffer(capacity: 4)
        XCTAssertEqual(write([1, 2, 3, 4, 5, 6], to: ring), 4)
        XCTAssertEqual(write([7, 8], to: ring), 0)
        XCTAssertEqual(read(2, from: ring), [1, 2])
        XCTAssertEqual(write([9, 10, 11], to: ring), 2)
        XCTAssertEqual(read(8, from: ring), [3, 4, 9, 10])
        XCTAssertEqual(read(1, from: ring), [])
    }

    func testWraparoundWithNonPowerOfTwoCapacity() {
        let ring = AudioRingBuffer(capacity: 5)
        for index in 0..<100 {
            let samples = (0..<3).map { Float(index * 3 + $0) }
            XCTAssertEqual(write(samples, to: ring), samples.count)
            XCTAssertEqual(read(3, from: ring), samples)
        }
    }

    func testConcurrentProducerAndConsumerPreserveSampleOrder() {
        let ring = AudioRingBuffer(capacity: 127)
        let count = 100_000
        let producer = expectation(description: "Producer completed")
        let consumer = expectation(description: "Consumer completed")
        let deadline = DispatchTime.now() + .seconds(10)

        DispatchQueue.global().async {
            defer { producer.fulfill() }
            let samples = (0..<count).map(Float.init)
            samples.withUnsafeBufferPointer { input in
                var offset = 0
                while offset < count, DispatchTime.now() < deadline {
                    let written = ring.write(from: input.baseAddress!.advanced(by: offset), count: min(53, count - offset))
                    offset += written
                    if written == 0 { Thread.sleep(forTimeInterval: 0.00001) }
                }
                XCTAssertEqual(offset, count)
            }
        }
        DispatchQueue.global().async {
            defer { consumer.fulfill() }
            var output = [Float](repeating: 0, count: 61)
            var received = [Float]()
            received.reserveCapacity(count)
            while received.count < count, DispatchTime.now() < deadline {
                let readCount = output.withUnsafeMutableBufferPointer {
                    ring.read(into: $0.baseAddress!, count: $0.count)
                }
                received.append(contentsOf: output.prefix(readCount))
                if readCount == 0 { Thread.sleep(forTimeInterval: 0.00001) }
            }
            XCTAssertEqual(received, (0..<count).map(Float.init))
        }
        wait(for: [producer, consumer], timeout: 12)
    }

    private func write(_ samples: [Float], to ring: AudioRingBuffer) -> Int {
        samples.withUnsafeBufferPointer { ring.write(from: $0.baseAddress!, count: $0.count) }
    }

    private func read(_ count: Int, from ring: AudioRingBuffer) -> [Float] {
        var output = [Float](repeating: 0, count: count)
        let received = output.withUnsafeMutableBufferPointer {
            ring.read(into: $0.baseAddress!, count: count)
        }
        return Array(output.prefix(received))
    }
}

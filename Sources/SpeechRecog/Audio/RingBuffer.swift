import Atomics

/// Single producer / single consumer queue. Each head has exactly one writer;
/// acquire/release ordering keeps samples alive until the consumer has read them.
final class AudioRingBuffer: @unchecked Sendable {
    private let capacity: Int
    private let buffer: UnsafeMutablePointer<Float>
    private let writeHead = ManagedAtomic<UInt64>(0)
    private let readHead = ManagedAtomic<UInt64>(0)

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
        self.buffer = .allocate(capacity: capacity)
        self.buffer.initialize(repeating: 0, count: capacity)
    }

    deinit {
        buffer.deallocate()
    }

    /// Producer: append what fits, dropping new samples rather than overwriting
    /// data that the consumer may currently be reading. Never blocks or allocates.
    @discardableResult
    func write(from source: UnsafePointer<Float>, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let head = writeHead.load(ordering: .relaxed)
        let read = readHead.load(ordering: .acquiring)
        let toWrite = min(count, capacity - Int(head &- read))
        guard toWrite > 0 else { return 0 }

        let offset = Int(head % UInt64(capacity))
        let first = min(toWrite, capacity - offset)
        buffer.advanced(by: offset).update(from: source, count: first)
        if first < toWrite {
            buffer.update(from: source.advanced(by: first), count: toWrite - first)
        }
        writeHead.store(head &+ UInt64(toWrite), ordering: .releasing)
        return toWrite
    }

    /// Consumer: read up to `count` samples. Returns number actually read.
    func read(into destination: UnsafeMutablePointer<Float>, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let head = readHead.load(ordering: .relaxed)
        let written = writeHead.load(ordering: .acquiring)
        let toRead = min(count, Int(written &- head))
        guard toRead > 0 else { return 0 }

        let offset = Int(head % UInt64(capacity))
        let first = min(toRead, capacity - offset)
        destination.update(from: buffer.advanced(by: offset), count: first)
        if first < toRead {
            destination.advanced(by: first).update(from: buffer, count: toRead - first)
        }
        readHead.store(head &+ UInt64(toRead), ordering: .releasing)
        return toRead
    }
}

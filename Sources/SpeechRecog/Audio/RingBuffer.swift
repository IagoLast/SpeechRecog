import Darwin

/// Lock-free single-producer single-consumer ring buffer for Float32 audio samples.
final class AudioRingBuffer {
    private let capacity: Int
    private let buffer: UnsafeMutablePointer<Float>
    private var _writeHead: Int64 = 0
    private var _readHead: Int64 = 0

    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = .allocate(capacity: capacity)
        self.buffer.initialize(repeating: 0, count: capacity)
    }

    deinit {
        buffer.deallocate()
    }

    var availableToRead: Int {
        OSMemoryBarrier()
        return Int(_writeHead - _readHead)
    }

    /// Producer: append samples. Drops oldest data if buffer is full.
    func write(from source: UnsafePointer<Float>, count: Int) {
        var remaining = count
        var srcOffset = 0
        while remaining > 0 {
            let idx = Int(_writeHead % Int64(capacity))
            let chunk = min(remaining, capacity - idx)
            buffer.advanced(by: idx).update(from: source.advanced(by: srcOffset), count: chunk)
            srcOffset += chunk
            remaining -= chunk
            OSMemoryBarrier()
            _writeHead += Int64(chunk)
        }
    }

    /// Consumer: read up to `count` samples. Returns number actually read.
    func read(into dest: UnsafeMutablePointer<Float>, count: Int) -> Int {
        let available = availableToRead
        let toRead = min(count, available)
        guard toRead > 0 else { return 0 }

        var remaining = toRead
        var dstOffset = 0
        while remaining > 0 {
            let idx = Int(_readHead % Int64(capacity))
            let chunk = min(remaining, capacity - idx)
            dest.advanced(by: dstOffset).update(from: buffer.advanced(by: idx), count: chunk)
            dstOffset += chunk
            remaining -= chunk
            OSMemoryBarrier()
            _readHead += Int64(chunk)
        }
        return toRead
    }
}

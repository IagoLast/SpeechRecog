import Foundation

/// Cross-process stop signal. The widget extension cannot see the app's
/// recorder, and the two processes do not need an App Group: a Darwin
/// notification reaches the recording process while its audio session is alive.
public enum RecordingSignal {
    public static let stopName = "es.speechrecog.notes.stop" as CFString

    public static func postStop() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(stopName),
            nil,
            nil,
            true
        )
    }

    /// The handler runs on an arbitrary thread. Hop to the main actor before
    /// touching the recorder.
    public static func addStopObserver(_ handler: @escaping @Sendable () -> Void) -> RecordingSignalToken {
        let box = DarwinBox(handler: handler)
        let pointer = Unmanaged.passUnretained(box).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            pointer,
            darwinStopCallback,
            stopName,
            nil,
            .deliverImmediately
        )
        return RecordingSignalToken(box: box, pointer: pointer)
    }
}

public final class RecordingSignalToken {
    fileprivate let box: DarwinBox
    fileprivate let pointer: UnsafeMutableRawPointer

    fileprivate init(box: DarwinBox, pointer: UnsafeMutableRawPointer) {
        self.box = box
        self.pointer = pointer
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            pointer,
            CFNotificationName(RecordingSignal.stopName),
            nil
        )
    }
}

final class DarwinBox {
    let handler: @Sendable () -> Void

    init(handler: @escaping @Sendable () -> Void) {
        self.handler = handler
    }
}

private let darwinStopCallback: CFNotificationCallback = { _, observer, _, _, _ in
    guard let observer else { return }
    let box = Unmanaged<DarwinBox>.fromOpaque(observer).takeUnretainedValue()
    box.handler()
}

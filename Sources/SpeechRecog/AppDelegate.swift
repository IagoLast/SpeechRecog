import AppKit
import AVFoundation
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Process Taps deliver silence without Screen Recording permission.
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
        }

        // Request microphone permission early so the user sees the prompt on first launch.
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            NSLog("[SpeechRecog] Microphone permission: %@", granted ? "granted" : "denied")
        }

        let coordinator = RecordingCoordinator()
        menuBarController = MenuBarController(coordinator: coordinator)
        menuBarController?.install()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.uninstall()
    }
}

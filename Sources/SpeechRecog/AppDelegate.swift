import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var coordinator: RecordingCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coordinator = RecordingCoordinator()
        self.coordinator = coordinator
        menuBarController = MenuBarController(coordinator: coordinator)
        menuBarController?.install()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.shutdown()
        menuBarController?.uninstall()
    }
}

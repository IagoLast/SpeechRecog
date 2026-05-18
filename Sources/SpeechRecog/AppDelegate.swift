import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coordinator = RecordingCoordinator()
        menuBarController = MenuBarController(coordinator: coordinator)
        menuBarController?.install()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.uninstall()
    }
}

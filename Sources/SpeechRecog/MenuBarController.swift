import AppKit
import Combine

@MainActor
final class MenuBarController {
    private let coordinator: RecordingCoordinator
    private var statusItem: NSStatusItem?
    private var preferencesWindow: NSWindow?
    private var cancellables: Set<AnyCancellable> = []

    init(coordinator: RecordingCoordinator) {
        self.coordinator = coordinator
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = Self.idleImage
        item.button?.image?.isTemplate = true
        item.menu = buildMenu()
        statusItem = item

        coordinator.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        coordinator.$audioLevel
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] level in self?.updateLevelDisplay(level) }
            .store(in: &cancellables)
    }

    func uninstall() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }

    private func render(state: RecordingCoordinator.State) {
        guard let button = statusItem?.button else { return }
        switch state {
        case .idle:
            button.image = Self.idleImage
            button.title = ""
        case .recording:
            button.image = Self.recordingImage
        case .transcribing:
            button.image = Self.transcribingImage
            button.title = ""
        }
        button.image?.isTemplate = true
        statusItem?.menu = buildMenu()
    }

    private func updateLevelDisplay(_ level: Float) {
        guard case .recording = coordinator.state else { return }
        guard let button = statusItem?.button else { return }
        let bars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇"]
        let idx = min(Int(level * Float(bars.count)), bars.count - 1)
        button.title = " " + bars[idx]
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let toggle = NSMenuItem(
            title: coordinator.state == .recording ? "Detener grabación" : "Iniciar grabación",
            action: #selector(toggleRecording),
            keyEquivalent: "r"
        )
        toggle.target = self
        menu.addItem(toggle)

        if case .transcribing(let progress) = coordinator.state {
            let info = NSMenuItem(title: "Transcribiendo… \(Int(progress * 100))%", action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
        }

        menu.addItem(.separator())

        let recordings = coordinator.store.listRecordings()
        if !recordings.isEmpty && coordinator.state == .idle {
            let retranscribeItem = NSMenuItem(title: "Re-transcribir", action: nil, keyEquivalent: "")
            let submenu = NSMenu()

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short

            for recording in recordings.prefix(20) {
                let title = dateFormatter.string(from: recording.createdAt)
                let item = NSMenuItem(title: title, action: #selector(retranscribeRecording(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = recording.audioURL
                submenu.addItem(item)
            }

            retranscribeItem.submenu = submenu
            menu.addItem(retranscribeItem)
            menu.addItem(.separator())
        }

        let openFolder = NSMenuItem(title: "Abrir carpeta de grabaciones", action: #selector(openRecordingsFolder), keyEquivalent: "o")
        openFolder.target = self
        menu.addItem(openFolder)

        let prefs = NSMenuItem(title: "Preferencias…", action: #selector(openPreferences), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Salir", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    @objc private func toggleRecording() {
        Task { await coordinator.toggleRecording() }
    }

    @objc private func retranscribeRecording(_ sender: NSMenuItem) {
        guard let audioURL = sender.representedObject as? URL else { return }
        let recordings = coordinator.store.listRecordings()
        guard let recording = recordings.first(where: { $0.audioURL == audioURL }) else { return }
        Task { await coordinator.retranscribe(recording: recording) }
    }

    @objc private func openRecordingsFolder() {
        NSWorkspace.shared.open(coordinator.recordingsFolder)
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow.make(settings: coordinator.settings)
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private static var idleImage: NSImage {
        NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "SpeechRecog")!
    }
    private static var recordingImage: NSImage {
        NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: "Grabando")!
    }
    private static var transcribingImage: NSImage {
        NSImage(systemSymbolName: "waveform.badge.magnifyingglass", accessibilityDescription: "Transcribiendo")!
    }
}

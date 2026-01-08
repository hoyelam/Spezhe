import AppKit
import SwiftUI
import KeyboardShortcuts

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var floatingPanelController: FloatingPanelController?

    public let recordingViewModel = RecordingViewModel()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        logInfo("Application launched", category: .app)

        // Initialize database and repositories
        _ = DatabaseManager.shared
        _ = RecordingRepository.shared
        _ = AudioFileManager.shared
        logInfo("Database and file manager initialized", category: .app)

        setupStatusItem()
        setupKeyboardShortcut()
        setupFloatingPanel()
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When dock icon is clicked and no windows are visible, show the main window
        if !flag {
            for window in NSApp.windows {
                if window.canBecomeMain {
                    window.makeKeyAndOrderFront(self)
                    return true
                }
            }
        }
        return true
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Spetra")
            button.action = #selector(togglePopover)
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Spetra", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func setupKeyboardShortcut() {
        KeyboardShortcuts.setShortcut(.init(.space, modifiers: [.control]), for: .toggleRecording)

        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            Task { @MainActor in
                await self?.recordingViewModel.toggleRecording()
            }
        }
    }

    private func setupFloatingPanel() {
        floatingPanelController = FloatingPanelController(viewModel: recordingViewModel)
        recordingViewModel.onShowPopup = { [weak self] show in
            if show {
                self?.floatingPanelController?.showPanel()
            } else {
                self?.floatingPanelController?.hidePanel()
            }
        }
    }

    @objc private func togglePopover() {
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }

        if popover == nil {
            popover = NSPopover()
            popover?.contentSize = NSSize(width: 280, height: 200)
            popover?.behavior = .transient
            popover?.contentViewController = NSHostingController(
                rootView: MenuBarView().environmentObject(recordingViewModel)
            )
        }

        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

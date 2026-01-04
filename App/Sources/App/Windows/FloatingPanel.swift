import AppKit

public class FloatingPanel: NSPanel {
    public var onCancel: (() -> Void)?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver // Highest level to stay on top
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.hidesOnDeactivate = false

        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }

    deinit {
        removeEventMonitors()
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return false
    }

    public override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    public func setupEventMonitors() {
        // Global monitor for when app is not focused
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                DispatchQueue.main.async {
                    self?.onCancel?()
                }
            }
        }

        // Local monitor for when app is focused
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                DispatchQueue.main.async {
                    self?.onCancel?()
                }
                return nil // Consume the event
            }
            return event
        }
    }

    public func removeEventMonitors() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    public func activatePanel() {
        orderFrontRegardless()
    }
}

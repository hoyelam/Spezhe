import AppKit
import SwiftUI

@MainActor
public class FloatingPanelController {
    private var panel: FloatingPanel?
    private let viewModel: RecordingViewModel

    public init(viewModel: RecordingViewModel) {
        self.viewModel = viewModel
    }

    public func showPanel() {
        if panel == nil {
            createPanel()
        }

        centerPanel()
        panel?.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel?.animator().alphaValue = 1.0
        }
    }

    public func hidePanel() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            panel?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
        })
    }

    private func createPanel() {
        let panelSize = NSSize(width: 240, height: 140)
        let contentRect = NSRect(origin: .zero, size: panelSize)

        panel = FloatingPanel(contentRect: contentRect)
        panel?.alphaValue = 0

        let hostingView = NSHostingView(rootView: RecordingPopupView(viewModel: viewModel))
        panel?.contentView = hostingView
    }

    private func centerPanel() {
        guard let panel = panel,
              let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelFrame = panel.frame

        let x = screenFrame.midX - panelFrame.width / 2
        let y = screenFrame.midY - panelFrame.height / 2

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

import AppKit
import SwiftUI

/// Owns the NSStatusItem (menu bar icon) and the two NSWindows.
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var displayWindow: NSWindow?
    private var controlWindow: NSWindow?
    private let server: ServerProcess

    init(server: ServerProcess) {
        self.server = server
        super.init()
        setupStatusItem()
        openDisplay()
    }

    // MARK: - Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "airplane", accessibilityDescription: "Skylight")
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Display", action: #selector(toggleDisplay), keyEquivalent: "d")
            .target = self
        menu.addItem(withTitle: "Control Panel", action: #selector(openControl), keyEquivalent: "c")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Skylight", action: #selector(quit), keyEquivalent: "q")
            .target = self
        statusItem.menu = menu
    }

    // MARK: - Display window

    @objc private func toggleDisplay() {
        if let w = displayWindow {
            if w.isVisible { w.orderOut(nil) } else { w.makeKeyAndOrderFront(nil) }
            return
        }
        openDisplay()
    }

    private func openDisplay() {
        let content = DisplayWindow()
            .environmentObject(server)
        let hosting = NSHostingController(rootView: content)

        let w = NSWindow(contentViewController: hosting)
        w.title = "Skylight"
        w.styleMask = [.borderless, .fullSizeContentView]
        w.backgroundColor = .black
        w.isOpaque = true
        w.level = .floating
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.setContentSize(NSSize(width: 1280, height: 720))
        w.center()
        w.makeKeyAndOrderFront(nil)
        displayWindow = w
    }

    // MARK: - Control window

    @objc private func openControl() {
        if let w = controlWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let content = ControlWindow()
            .environmentObject(server)
        let hosting = NSHostingController(rootView: content)

        let w = NSWindow(contentViewController: hosting)
        w.title = "Skylight — Control"
        w.styleMask = [.titled, .closable, .resizable]
        w.setContentSize(NSSize(width: 380, height: 700))
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Nil out the reference when the user closes it so we re-create fresh next time.
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: w,
            queue: .main
        ) { [weak self] _ in self?.controlWindow = nil }

        controlWindow = w
    }

    // MARK: - Quit

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

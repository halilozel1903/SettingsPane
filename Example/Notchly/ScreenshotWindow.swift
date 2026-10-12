import AppKit
import SwiftUI

/// Prepares the windows of a screenshot scene: the light appearance, no state restoration, the
/// app in front. Put it in the background of a window's content.
///
/// The Settings window is captured with `screencapture -l <window id>` by
/// scripts/screenshots-mac.sh, because only a real `Settings` scene gives a `TabView` its
/// toolbar. The renderer below is the fallback for when that fails.
struct ScreenshotWindow: NSViewRepresentable {
    enum Role {
        /// The Settings scene's window: the one to capture.
        case settings
        /// The main window that opened it. Hidden once the Settings window is up.
        case launcher
    }

    let role: Role

    func makeNSView(context: Context) -> NSView {
        ConfiguringView(role: role)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class ConfiguringView: NSView {
        private let role: Role
        private var isConfigured = false

        init(role: Role) {
            self.role = role
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not used")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, !isConfigured else { return }
            isConfigured = true

            window.appearance = NSAppearance(named: .aqua)
            window.isRestorable = false
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate()

            switch role {
            case .settings:
                ScreenshotCoordinator.shared.settingsWindowAppeared(window)
            case .launcher:
                ScreenshotCoordinator.shared.launcherWindowAppeared(window)
            }
        }
    }
}

/// Decides which window is captured, and hides every other one.
@MainActor
final class ScreenshotCoordinator {
    static let shared = ScreenshotCoordinator()

    private var settingsWindow: NSWindow?
    private var renderer: ScreenshotRenderer?

    func launcherWindowAppeared(_ window: NSWindow) {
        window.center()
        window.makeKeyAndOrderFront(nil)
        Task {
            // The Settings window opens within a second or two. If it never does, capture this one.
            try? await Task.sleep(for: .seconds(4))
            if self.settingsWindow == nil {
                FileHandle.standardError.write(Data("The Settings window did not open; capturing the main window\n".utf8))
                self.capture(window)
            }
        }
    }

    func settingsWindowAppeared(_ window: NSWindow) {
        guard settingsWindow == nil else { return }
        settingsWindow = window
        Task {
            // Let SwiftUI size the window to the pane before centering it.
            try? await Task.sleep(for: .seconds(1))
            window.center()
            window.makeKeyAndOrderFront(nil)
            self.capture(window)
        }
    }

    private func capture(_ window: NSWindow) {
        guard renderer == nil else { return }
        for other in NSApplication.shared.windows where other !== window && other.isVisible {
            other.orderOut(nil)
        }
        renderer = ScreenshotRenderer(window: window, path: ScreenshotScene.renderPath)
    }
}

/// The fallback: draws the window into a 2x bitmap with `cacheDisplay`, refuses a blank result,
/// writes the PNG and quits. Exits with status 1 on any failure so the CI script can give up.
/// `cacheDisplay` leaves tab views and grouped forms empty, which is why `screencapture` goes first.
@MainActor
final class ScreenshotRenderer {
    private let window: NSWindow

    init(window: NSWindow, path: String?) {
        self.window = window
        guard let path else { return }
        Task {
            // Give SwiftUI and AppKit time to lay out the pane and draw controls and symbols.
            try? await Task.sleep(for: .seconds(3))
            self.render(to: path)
        }
    }

    private func render(to path: String) {
        // The frame view holds the title bar and toolbar as well as the content.
        guard let view = window.contentView?.superview ?? window.contentView else {
            return fail("The window has no content view")
        }
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()

        let bounds = view.bounds
        let scale: CGFloat = 2
        guard bounds.width > 0, bounds.height > 0,
              let bitmap = NSBitmapImageRep(
                  bitmapDataPlanes: nil,
                  pixelsWide: Int(bounds.width * scale),
                  pixelsHigh: Int(bounds.height * scale),
                  bitsPerSample: 8,
                  samplesPerPixel: 4,
                  hasAlpha: true,
                  isPlanar: false,
                  colorSpaceName: .deviceRGB,
                  bytesPerRow: 0,
                  bitsPerPixel: 0
              )
        else { return fail("Could not create a bitmap for \(bounds)") }

        // The bitmap's size in points against its pixel size makes the view draw at 2x.
        bitmap.size = bounds.size
        view.cacheDisplay(in: bounds, to: bitmap)

        guard Self.distinctColorCount(in: bitmap) > 24 else {
            return fail("The rendered image is blank")
        }
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            return fail("Could not encode the PNG")
        }
        do {
            try png.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            return fail("Could not write \(path): \(error.localizedDescription)")
        }
        print("Rendered \(path) (\(bitmap.pixelsWide)x\(bitmap.pixelsHigh), \(png.count) bytes)")
        exit(0)
    }

    /// Samples a grid of pixels. A blank or single-color image has only a handful of colors.
    private static func distinctColorCount(in bitmap: NSBitmapImageRep) -> Int {
        var colors = Set<UInt32>()
        let step = max(1, min(bitmap.pixelsWide, bitmap.pixelsHigh) / 60)
        for y in stride(from: 0, to: bitmap.pixelsHigh, by: step) {
            for x in stride(from: 0, to: bitmap.pixelsWide, by: step) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
                colors.insert(channel(color.redComponent) << 16 | channel(color.greenComponent) << 8 | channel(color.blueComponent))
            }
        }
        return colors.count
    }

    private static func channel(_ component: CGFloat) -> UInt32 {
        UInt32(min(255, max(0, (component * 255).rounded())))
    }

    private func fail(_ message: String) {
        FileHandle.standardError.write(Data("Screenshot failed: \(message)\n".utf8))
        exit(1)
    }
}

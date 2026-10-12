import SettingsPane
import SwiftUI

/// Scenes used by CI to capture the README screenshots.
///
/// Launch with `-screenshot <scene>`: the app opens its real Settings window on a fixed pane and
/// style, with fresh defaults and the light appearance. A `mac-` prefix is accepted too, so
/// `-screenshot mac-general` is the same as `-screenshot general`. Normal launches are unaffected.
enum ScreenshotScene: String, Sendable {
    /// The toolbar style on the General pane.
    case general
    /// The toolbar style on the Appearance pane.
    case appearance
    /// The sidebar style on the Accounts pane.
    case sidebar
    /// The toolbar style on the Advanced pane, with the reset confirmation closed.
    case advanced

    static var current: ScreenshotScene? {
        guard var name = argument(after: "-screenshot") else { return nil }
        if name.hasPrefix("mac-") {
            name.removeFirst(4)
        }
        return ScreenshotScene(rawValue: name)
    }

    /// Where `-render-screenshot` asks the PNG to be written.
    static var renderPath: String? {
        argument(after: "-render-screenshot")
    }

    private static func argument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    var style: SettingsPaneStyle {
        self == .sidebar ? .sidebar : .toolbar
    }

    var pane: PaneID {
        switch self {
        case .general: .general
        case .appearance: .appearance
        case .sidebar: .accounts
        case .advanced: .advanced
        }
    }
}

/// The main window in screenshot mode. It opens the Settings window, which then hides it.
///
/// It shows the same settings itself, so if the Settings window ever fails to open, the capture
/// still has the panes to show (with plain tabs instead of the toolbar).
struct ScreenshotLauncher: View {
    let scene: ScreenshotScene
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        NotchlySettings(screenshot: scene)
            .background(ScreenshotWindow(role: .launcher))
            .task {
                try? await Task.sleep(for: .milliseconds(800))
                openSettings()
            }
    }
}

import SettingsPane
import SwiftUI

/// Notchly, a made-up utility that lives in the MacBook notch, showing off SettingsPane.
@main
struct NotchlyApp: App {
    init() {
        // Every @AppStorage and @SettingsDefault reads these defaults until the user changes a value.
        NotchlyKeys.all.register(in: AppDefaults.store)
    }

    var body: some Scene {
        WindowGroup("Notchly") {
            Group {
                if let scene = ScreenshotScene.current {
                    // Opens the Settings window on a fixed pane, for scripts/screenshots-mac.sh.
                    ScreenshotLauncher(scene: scene)
                } else {
                    HomeView()
                }
            }
            .settingsDefaults(AppDefaults.store)
        }
        .windowResizability(.contentSize)

        // The Settings scene gives the app its "Settings…" menu item and ⌘, for free.
        Settings {
            Group {
                if let scene = ScreenshotScene.current {
                    NotchlySettings(screenshot: scene)
                        .background(ScreenshotWindow(role: .settings))
                } else {
                    NotchlySettings(screenshot: nil)
                }
            }
            .settingsDefaults(AppDefaults.store)
        }
    }
}

/// The content of the Settings window.
struct NotchlySettings: View {
    let screenshot: ScreenshotScene?
    @AppStorage(NotchlyKeys.settingsStyle) private var style: SettingsPaneStyle

    var body: some View {
        SettingsPaneView(
            style: screenshot?.style ?? style,
            defaultPane: screenshot?.pane,
            persistence: screenshot == nil ? PanePersistence(key: "Notchly.lastSettingsPane") : nil
        ) {
            Pane("General", systemImage: "gearshape", tint: .gray) {
                GeneralPane()
            }
            Pane("Appearance", systemImage: "paintpalette", tint: .blue) {
                AppearancePane()
            }
            Pane("Shortcuts", systemImage: "command", tint: .indigo) {
                ShortcutsPane()
            }
            Pane("Accounts", systemImage: "person.crop.circle", tint: .orange) {
                AccountsPane()
            }
            Pane("Advanced", systemImage: "gearshape.2", tint: .gray) {
                AdvancedPane()
            }
        }
        .preferredColorScheme(screenshot == nil ? nil : .light)
    }
}

/// The app's main window: a short introduction and links into the settings.
struct HomeView: View {
    var body: some View {
        VStack(spacing: 14) {
            NotchGlyph()
                .padding(.bottom, 6)
            Text(verbatim: "Notchly")
                .font(.largeTitle.weight(.bold))
            Text("Your MacBook notch, with music, calendar and battery at a glance.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                SettingsLink {
                    Text("Open Settings…")
                }
                SettingsPaneLink("Appearance…", pane: .appearance)
                SettingsPaneLink("Accounts…", pane: .accounts)
            }
            .padding(.top, 8)

            Text("Press ⌘, at any time, or open \(Text(verbatim: "notchly://settings/shortcuts").font(.callout.monospaced())).")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 520)
        .opensSettings(for: NotchlyLinks.scheme)
    }
}

/// A notch with a tiny equalizer, the app's mark.
struct NotchGlyph: View {
    var body: some View {
        ZStack {
            UnevenRoundedRectangle(bottomLeadingRadius: 18, bottomTrailingRadius: 18, style: .continuous)
                .fill(.black)
                .frame(width: 150, height: 40)
            HStack(spacing: 3) {
                ForEach(Array([10.0, 18, 13, 22, 9].enumerated()), id: \.offset) { item in
                    Capsule()
                        .fill(Color.purple.gradient)
                        .frame(width: 4, height: item.element)
                }
            }
        }
    }
}

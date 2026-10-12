import SettingsPane
import SwiftUI

struct ShortcutsPane: View {
    @AppStorage(NotchlyKeys.shortcutsEnabled) private var shortcutsEnabled: Bool

    var body: some View {
        SettingsForm {
            SettingsRow("Global shortcuts") {
                Toggle("Enable keyboard shortcuts", isOn: $shortcutsEnabled)
            }

            SettingsSection {
                ForEach(NotchlyShortcut.all) { shortcut in
                    SettingsRow(shortcut.title) {
                        KeyCaps(keys: shortcut.keys)
                            .opacity(shortcutsEnabled ? 1 : 0.4)
                    }
                }
            } footer: {
                Text("Shortcuts work in every app while Notchly is running.")
            }

            SettingsSection {
                SettingsRow {
                    SettingsResetButton(pane: .shortcuts, keys: NotchlyKeys.all)
                }
            }
        }
    }
}

struct NotchlyShortcut: Identifiable {
    let title: String
    let keys: [String]

    var id: String { title }

    static let all = [
        NotchlyShortcut(title: "Open the notch", keys: ["⌥", "⌘", "N"]),
        NotchlyShortcut(title: "Play or pause", keys: ["⌥", "⌘", "P"]),
        NotchlyShortcut(title: "Next track", keys: ["⌥", "⌘", "→"]),
        NotchlyShortcut(title: "Show the shelf", keys: ["⌃", "⌥", "S"]),
        NotchlyShortcut(title: "Join the next meeting", keys: ["⌃", "⌥", "J"]),
    ]
}

/// Keys drawn as keycaps.
struct KeyCaps: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(keys.enumerated()), id: \.offset) { item in
                Text(verbatim: item.element)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .frame(minWidth: 22, minHeight: 20)
                    .padding(.horizontal, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .shadow(color: .black.opacity(0.15), radius: 0, y: 1)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(.black.opacity(0.12), lineWidth: 1)
                    }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(keys.joined(separator: " "))
    }
}

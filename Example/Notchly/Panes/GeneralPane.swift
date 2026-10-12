import SettingsPane
import SwiftUI

struct GeneralPane: View {
    @AppStorage(NotchlyKeys.launchAtLogin) private var launchAtLogin: Bool
    @AppStorage(NotchlyKeys.showsMenuBarIcon) private var showsMenuBarIcon: Bool
    @AppStorage(NotchlyKeys.notchStyle) private var notchStyle: NotchStyle
    @AppStorage(NotchlyKeys.hidesInFullScreen) private var hidesInFullScreen: Bool
    @SettingsDefault(NotchlyKeys.hoverDelay, store: AppDefaults.store) private var hoverDelay: Double
    @AppStorage(NotchlyKeys.checksForUpdates) private var checksForUpdates: Bool
    @AppStorage(NotchlyKeys.updateChannel) private var updateChannel: UpdateChannel

    var body: some View {
        SettingsForm {
            SettingsRow("Startup") {
                Toggle("Open Notchly at login", isOn: $launchAtLogin)
                Toggle("Show Notchly in the menu bar", isOn: $showsMenuBarIcon)
            }
            SettingsRow("Notch style") {
                Picker("Notch style", selection: $notchStyle) {
                    ForEach(NotchStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }
            SettingsRow("Full screen") {
                Toggle("Hide the notch in full-screen apps", isOn: $hidesInFullScreen)
                    .fixedSize()
            }
            SettingsRow("Open on hover") {
                HStack(spacing: 10) {
                    Slider(value: $hoverDelay, in: 0...1, step: 0.1)
                        .frame(width: 180)
                    Text(String(format: "%.1f s", hoverDelay))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            SettingsSection {
                SettingsRow("Updates") {
                    Toggle("Check for updates automatically", isOn: $checksForUpdates)
                    Picker("Channel", selection: $updateChannel) {
                        ForEach(UpdateChannel.allCases) { channel in
                            Text(channel.title).tag(channel)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(!checksForUpdates)
                }
            } footer: {
                Text("Beta releases arrive a week earlier and may be less stable.")
            }

            SettingsSection {
                SettingsRow {
                    SettingsResetButton(pane: .general, keys: NotchlyKeys.all)
                }
            }
        }
    }
}

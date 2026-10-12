import SettingsPane
import SwiftUI

struct AppearancePane: View {
    @AppStorage(NotchlyKeys.theme) private var theme: NotchTheme
    @AppStorage(NotchlyKeys.accent) private var accent: NotchAccent
    @AppStorage(NotchlyKeys.notchWidth) private var notchWidth: Double
    @AppStorage(NotchlyKeys.showsAlbumArt) private var showsAlbumArt: Bool
    @AppStorage(NotchlyKeys.showsBattery) private var showsBattery: Bool
    @AppStorage(NotchlyKeys.reducesMotion) private var reducesMotion: Bool

    var body: some View {
        SettingsForm {
            SettingsRow("Preview") {
                NotchPreview(
                    width: notchWidth,
                    accent: accent.color,
                    isDark: theme == .dark,
                    showsAlbumArt: showsAlbumArt,
                    showsBattery: showsBattery
                )
                // Lines the "Preview:" label up with the top of the preview.
                .alignmentGuide(.firstTextBaseline) { dimensions in dimensions[.top] + 13 }
            }
            SettingsRow("Theme") {
                Picker("Theme", selection: $theme) {
                    ForEach(NotchTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
            SettingsRow("Accent color") {
                AccentPicker(selection: $accent)
                    .alignmentGuide(.firstTextBaseline) { dimensions in dimensions[VerticalAlignment.center] + 4 }
            }
            SettingsRow("Notch width") {
                HStack(spacing: 10) {
                    Slider(value: $notchWidth, in: 180...320, step: 10)
                        .frame(width: 180)
                    Text("\(Int(notchWidth)) pt")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            SettingsRow("Show") {
                Toggle("Album art while music plays", isOn: $showsAlbumArt)
                Toggle("Battery level", isOn: $showsBattery)
                Toggle("Reduce motion", isOn: $reducesMotion)
            }

            SettingsSection {
                SettingsRow {
                    SettingsResetButton(pane: .appearance, keys: NotchlyKeys.all)
                }
            }
        }
    }
}

/// A row of color swatches, like the accent colors in System Settings.
struct AccentPicker: View {
    @Binding var selection: NotchAccent

    var body: some View {
        HStack(spacing: 8) {
            ForEach(NotchAccent.allCases) { accent in
                Button {
                    selection = accent
                } label: {
                    Circle()
                        .fill(accent.color.gradient)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Circle()
                                .strokeBorder(.black.opacity(0.12), lineWidth: 1)
                        }
                        .padding(3)
                        .overlay {
                            if accent == selection {
                                Circle()
                                    .strokeBorder(accent.color, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .help(accent.title)
                .accessibilityLabel(accent.title)
                .accessibilityAddTraits(accent == selection ? .isSelected : [])
            }
        }
    }
}

/// The notch as it would look on the desktop.
struct NotchPreview: View {
    let width: Double
    let accent: Color
    let isDark: Bool
    let showsAlbumArt: Bool
    let showsBattery: Bool

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.16, green: 0.18, blue: 0.30), Color(red: 0.08, green: 0.09, blue: 0.16)]
                    : [Color(red: 0.62, green: 0.76, blue: 1.0), Color(red: 0.95, green: 0.78, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 8) {
                if showsAlbumArt {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(LinearGradient(colors: [accent, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 20, height: 20)
                }
                HStack(spacing: 2) {
                    ForEach(Array([8.0, 14, 10, 16, 7].enumerated()), id: \.offset) { item in
                        Capsule()
                            .fill(accent)
                            .frame(width: 3, height: item.element)
                    }
                }
                Spacer(minLength: 4)
                if showsBattery {
                    HStack(spacing: 3) {
                        Text(verbatim: "82%")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                        Image(systemName: "battery.75percent")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(width: width * 0.9, height: 32)
            .background(
                UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14, style: .continuous)
                    .fill(.black)
            )
        }
        .frame(width: 300, height: 74)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.black.opacity(0.1), lineWidth: 1)
        }
        .accessibilityElement()
        .accessibilityLabel("Notch preview")
    }
}

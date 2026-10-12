import SwiftUI

/// The layout of a pane's settings, in the style of the window:
///
/// - **Toolbar style**: the classic Mac form, a grid with right-aligned labels ending in a colon
///   and the controls in a column next to them, centered in the pane.
/// - **Sidebar style**: a grouped `Form`, as in System Settings.
///
/// ```swift
/// SettingsForm {
///     SettingsRow("Startup") {
///         Toggle("Open at login", isOn: $launchAtLogin)
///         Toggle("Show in the menu bar", isOn: $showsMenuBarIcon)
///     }
///     SettingsRow("Theme") {
///         Picker("Theme", selection: $theme) { … }
///             .labelsHidden()
///     }
///     SettingsSection("Updates") {
///         SettingsRow { Toggle("Check automatically", isOn: $checksForUpdates) }
///     }
/// }
/// ```
public struct SettingsForm<Content: View>: View {
    @Environment(\.settingsPaneStyle) private var style
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        switch style {
        case .toolbar:
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 8, verticalSpacing: 12) {
                content
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        case .sidebar:
            Form {
                content
            }
            .formStyle(.grouped)
        }
    }
}

/// One labeled row of a ``SettingsForm``.
///
/// In the toolbar style the label sits right-aligned in the label column, with a colon added
/// (`"Theme"` reads `Theme:`), and the content stacks in the control column, as in classic Mac
/// settings. In the sidebar style the row is a `LabeledContent` in the grouped form, without the
/// colon. A row without a label puts its content in the control column, or in a plain form row.
public struct SettingsRow<Content: View>: View {
    @Environment(\.settingsPaneStyle) private var style
    private let title: String?
    private let content: Content

    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public init(@ViewBuilder content: () -> Content) {
        self.title = nil
        self.content = content()
    }

    public var body: some View {
        switch style {
        case .toolbar:
            GridRow(alignment: .firstTextBaseline) {
                if let title {
                    Text(SettingsLabel.classic(title))
                        .gridColumnAlignment(.trailing)
                } else {
                    Color.clear
                        .gridCellUnsizedAxes([.horizontal, .vertical])
                }
                VStack(alignment: .leading, spacing: 8) {
                    content
                }
                .gridColumnAlignment(.leading)
            }
        case .sidebar:
            if let title {
                LabeledContent {
                    VStack(alignment: .trailing, spacing: 6) {
                        content
                    }
                } label: {
                    Text(SettingsLabel.plain(title))
                }
            } else {
                content
            }
        }
    }
}

/// A group of rows in a ``SettingsForm``.
///
/// In the toolbar style a section starts with a separator across the form, then its optional
/// title, its rows and its optional footer under the controls. In the sidebar style it is a
/// `Section` of the grouped form, with the title as its header.
public struct SettingsSection<Content: View, Footer: View>: View {
    @Environment(\.settingsPaneStyle) private var style
    private let title: String?
    private let showsSeparator: Bool
    private let content: Content
    private let footer: Footer

    /// - Parameters:
    ///   - title: The section's title.
    ///   - showsSeparator: Whether a separator precedes the section in the toolbar style. Turn it
    ///     off for a section at the top of a pane.
    public init(
        _ title: String? = nil,
        showsSeparator: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.showsSeparator = showsSeparator
        self.content = content()
        self.footer = footer()
    }

    public var body: some View {
        switch style {
        case .toolbar:
            if showsSeparator {
                Divider()
                    .gridCellUnsizedAxes(.horizontal)
                    .padding(.vertical, 2)
            }
            if let title {
                Text(title)
                    .font(.headline)
            }
            content
            if Footer.self != EmptyView.self {
                GridRow {
                    Color.clear
                        .gridCellUnsizedAxes([.horizontal, .vertical])
                    footer
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 320, alignment: .leading)
                }
            }
        case .sidebar:
            Section {
                content
            } header: {
                if let title {
                    Text(title)
                }
            } footer: {
                footer
            }
        }
    }
}

extension SettingsSection where Footer == EmptyView {
    public init(_ title: String? = nil, showsSeparator: Bool = true, @ViewBuilder content: () -> Content) {
        self.init(title, showsSeparator: showsSeparator, content: content, footer: { EmptyView() })
    }
}

/// How row labels read in each style.
enum SettingsLabel {
    /// `"Theme"` → `"Theme:"`. A label that already ends in a colon is kept.
    static func classic(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasSuffix(":") else { return trimmed }
        return trimmed + ":"
    }

    /// `"Theme:"` → `"Theme"`.
    static func plain(_ title: String) -> String {
        var trimmed = title.trimmingCharacters(in: .whitespaces)
        while trimmed.hasSuffix(":") {
            trimmed.removeLast()
        }
        return trimmed.trimmingCharacters(in: .whitespaces)
    }
}

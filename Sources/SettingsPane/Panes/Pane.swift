import SwiftUI

/// One pane of a settings window: a title, an SF Symbol and its content.
///
/// ```swift
/// SettingsPaneView {
///     Pane("General", systemImage: "gearshape") {
///         GeneralSettings()
///     }
///     Pane("Accounts", systemImage: "person.crop.circle", tint: .blue) {
///         AccountSettings()
///     }
/// }
/// ```
public struct Pane: Identifiable {
    /// The pane's identifier. Made from the title unless given.
    public let id: PaneID
    /// The title in the toolbar or the sidebar, and the window title while the pane is shown.
    public let title: String
    /// The SF Symbol in the toolbar or the sidebar.
    public let systemImage: String
    /// The color of the rounded icon tile in the sidebar style.
    public let tint: Color
    /// The pane's content, type-erased so panes of different types can be listed together.
    public let content: AnyView

    /// - Parameters:
    ///   - title: The pane's title.
    ///   - systemImage: The name of an SF Symbol.
    ///   - id: The identifier used for selection, persistence and deep links. Defaults to
    ///     ``PaneID/init(title:)``.
    ///   - tint: The color of the icon tile in the sidebar style.
    ///   - content: The pane's settings, usually a ``SettingsForm``.
    @MainActor
    public init<Content: View>(
        _ title: String,
        systemImage: String,
        id: PaneID? = nil,
        tint: Color = .gray,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id ?? PaneID(title: title)
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = AnyView(content())
    }
}

/// Builds the list of panes of a ``SettingsPaneView``. Supports `if`, `if let`, `switch`, `for`
/// and `if #available`.
@resultBuilder
public enum SettingsPaneBuilder {
    public static func buildExpression(_ pane: Pane) -> [Pane] {
        [pane]
    }

    public static func buildExpression(_ panes: [Pane]) -> [Pane] {
        panes
    }

    public static func buildBlock(_ components: [Pane]...) -> [Pane] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Pane]?) -> [Pane] {
        component ?? []
    }

    public static func buildEither(first component: [Pane]) -> [Pane] {
        component
    }

    public static func buildEither(second component: [Pane]) -> [Pane] {
        component
    }

    public static func buildArray(_ components: [[Pane]]) -> [Pane] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [Pane]) -> [Pane] {
        component
    }
}

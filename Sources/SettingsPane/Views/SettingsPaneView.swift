import SwiftUI

/// The content of a Settings window: panes in a toolbar or in a sidebar.
///
/// ```swift
/// @main
/// struct NotchlyApp: App {
///     var body: some Scene {
///         WindowGroup { ContentView() }
///
///         Settings {                       // ⌘, opens it
///             SettingsPaneView {
///                 Pane("General", systemImage: "gearshape") { GeneralPane() }
///                 Pane("Appearance", systemImage: "paintpalette") { AppearancePane() }
///                 Pane("Advanced", systemImage: "gearshape.2") { AdvancedPane() }
///             }
///         }
///     }
/// }
/// ```
///
/// - **Toolbar style**: the panes are toolbar buttons and the window takes each pane's height,
///   animating between panes as Mac settings windows do.
/// - **Sidebar style**: System Settings' layout, with a sidebar of colored icons and a fixed size.
///
/// The view remembers the last pane, and `openSettings(pane:)` opens the window on any pane.
public struct SettingsPaneView: View {
    private let style: SettingsPaneStyle
    private let panes: [Pane]
    private let defaultPane: PaneID?
    private let persistence: PanePersistence?
    private let layout: SettingsPaneLayout
    @ObservedObject private var router: SettingsRouter
    @Environment(\.settingsDefaults) private var defaults
    @State private var selection: PaneID?

    /// - Parameters:
    ///   - style: ``SettingsPaneStyle/toolbar`` or ``SettingsPaneStyle/sidebar``.
    ///   - defaultPane: The pane shown when no last pane is remembered. The first pane by default.
    ///   - persistence: Where the last pane is remembered, or `nil` to always start on
    ///     `defaultPane`.
    ///   - layout: The toolbar width and the sidebar window size.
    ///   - router: The router `openSettings(pane:)` talks to. ``SettingsRouter/shared`` by default.
    ///   - panes: The panes, in order.
    public init(
        style: SettingsPaneStyle = .toolbar,
        defaultPane: PaneID? = nil,
        persistence: PanePersistence? = .standard,
        layout: SettingsPaneLayout = SettingsPaneLayout(),
        router: SettingsRouter? = nil,
        @SettingsPaneBuilder panes: () -> [Pane]
    ) {
        var seen = Set<PaneID>()
        self.style = style
        self.panes = panes().filter { seen.insert($0.id).inserted }
        self.defaultPane = defaultPane
        self.persistence = persistence
        self.layout = layout
        self._router = ObservedObject(wrappedValue: router ?? SettingsRouter.shared)
    }

    public var body: some View {
        Group {
            if panes.isEmpty {
                ContentUnavailableView("No Settings", systemImage: "gearshape")
                    .frame(width: layout.toolbarWidth, height: 240)
            } else {
                switch style {
                case .toolbar:
                    toolbarStyle
                case .sidebar:
                    sidebarStyle
                }
            }
        }
        .onAppear {
            if !isValid(selection) {
                selection = initialSelection
            }
            takeRequest()
        }
        .onChange(of: selection) { oldValue, newValue in
            guard let newValue, paneIDs.contains(newValue) else {
                // A click on the empty part of the sidebar deselects; keep showing the pane.
                selection = isValid(oldValue) ? oldValue : initialSelection
                return
            }
            persistence?.save(newValue, to: defaults)
        }
        .onChange(of: paneIDs) { _, _ in
            if !isValid(selection) {
                selection = initialSelection
            }
        }
        .onChange(of: router.pendingRequest) { _, _ in
            takeRequest()
        }
    }

    // MARK: Toolbar style

    /// A `TabView` in a `Settings` scene becomes the toolbar of a Mac settings window, and the window
    /// animates to the height of each tab's content. The content has a fixed width and its own height.
    private var toolbarStyle: some View {
        TabView(selection: $selection) {
            ForEach(panes) { pane in
                pane.content
                    .settingsPaneStyle(.toolbar)
                    .frame(width: layout.toolbarWidth)
                    .fixedSize(horizontal: false, vertical: true)
                    .tabItem {
                        Label(pane.title, systemImage: pane.systemImage)
                    }
                    .tag(Optional(pane.id))
            }
        }
    }

    // MARK: Sidebar style

    private var sidebarStyle: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(panes) { pane in
                    Label {
                        Text(pane.title)
                    } icon: {
                        PaneIcon(systemImage: pane.systemImage, tint: pane.tint)
                    }
                    .tag(Optional(pane.id))
                }
            }
            .navigationSplitViewColumnWidth(layout.sidebarWidth)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            if let pane = selectedPane {
                pane.content
                    .settingsPaneStyle(.sidebar)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .navigationTitle(pane.title)
            }
        }
        .frame(width: layout.sidebarWindowSize.width, height: layout.sidebarWindowSize.height)
    }

    // MARK: Selection

    private var paneIDs: [PaneID] {
        panes.map(\.id)
    }

    /// The remembered pane, else `defaultPane`, else the first.
    private var initialSelection: PaneID? {
        let restored = persistence?.restore(from: defaults, panes: paneIDs)
        return PaneSelection.resolve(preferred: [restored, defaultPane], in: paneIDs)
    }

    private var selectedPane: Pane? {
        let id = isValid(selection) ? selection : initialSelection
        return panes.first { $0.id == id }
    }

    private func isValid(_ pane: PaneID?) -> Bool {
        guard let pane else { return false }
        return paneIDs.contains(pane)
    }

    private func takeRequest() {
        guard let request = router.takeRequest(), paneIDs.contains(request.pane) else { return }
        selection = request.pane
    }
}

/// The colored rounded tile behind a pane's symbol in the sidebar, as in System Settings.
struct PaneIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

import Combine
import SwiftUI

/// A request to show a pane, with a serial number so asking for the same pane twice is still a
/// change.
public struct PaneRequest: Equatable, Sendable {
    public let pane: PaneID
    public let serial: Int

    public init(pane: PaneID, serial: Int) {
        self.pane = pane
        self.serial = serial
    }
}

/// Carries "show this pane" from anywhere in the app to the ``SettingsPaneView``, whether its
/// window is already open or about to open.
///
/// You rarely use it directly: `openSettings(pane:)` asks the shared router and opens the window.
@MainActor
public final class SettingsRouter: ObservableObject {
    /// The router every ``SettingsPaneView`` listens to unless it is given another one.
    public static let shared = SettingsRouter()

    /// The pending request, until the settings view takes it.
    @Published public private(set) var pendingRequest: PaneRequest?
    private var serial = 0

    public init() {}

    /// Asks the settings view to show a pane.
    public func show(_ pane: PaneID) {
        serial += 1
        pendingRequest = PaneRequest(pane: pane, serial: serial)
    }

    /// Returns the pending request and clears it.
    public func takeRequest() -> PaneRequest? {
        guard let request = pendingRequest else { return nil }
        pendingRequest = nil
        return request
    }
}

extension OpenSettingsAction {
    /// Opens the Settings window on a pane, or switches the open window to it.
    ///
    /// ```swift
    /// @Environment(\.openSettings) private var openSettings
    ///
    /// Button("Manage Accounts…") {
    ///     openSettings(pane: "accounts")
    /// }
    /// ```
    @MainActor
    public func callAsFunction(pane: PaneID) {
        callAsFunction(pane: pane, router: SettingsRouter.shared)
    }

    /// Opens the Settings window on a pane through a router of your own.
    @MainActor
    public func callAsFunction(pane: PaneID, router: SettingsRouter) {
        router.show(pane)
        callAsFunction()
    }
}

/// A button that opens the Settings window on a pane, like `SettingsLink` with a destination.
///
/// ```swift
/// SettingsPaneLink("Manage Accounts…", pane: "accounts")
/// ```
public struct SettingsPaneLink<Label: View>: View {
    @Environment(\.openSettings) private var openSettings
    private let pane: PaneID
    private let label: Label

    public init(pane: PaneID, @ViewBuilder label: () -> Label) {
        self.pane = pane
        self.label = label()
    }

    public var body: some View {
        Button {
            openSettings(pane: pane)
        } label: {
            label
        }
    }
}

extension SettingsPaneLink where Label == Text {
    public init(_ title: String, pane: PaneID) {
        self.init(pane: pane) {
            Text(title)
        }
    }
}

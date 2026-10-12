import Foundation
import Testing
@testable import SettingsPane

@Suite("Deep links")
struct SettingsURLSchemeTests {
    let links = SettingsURLScheme(scheme: "notchly")

    @Test func buildsAPaneURL() {
        #expect(links.url(for: .accounts)?.absoluteString == "notchly://settings/accounts")
        #expect(links.settingsURL?.absoluteString == "notchly://settings")
    }

    @Test func readsThePaneFromThePath() throws {
        let url = try #require(URL(string: "notchly://settings/advanced"))
        #expect(links.pane(from: url) == .advanced)
    }

    @Test func readsThePaneFromTheQuery() throws {
        let url = try #require(URL(string: "notchly://settings?pane=appearance"))
        #expect(links.pane(from: url) == .appearance)
    }

    @Test func roundTrip() throws {
        let url = try #require(links.url(for: .shortcuts))
        #expect(links.pane(from: url) == .shortcuts)
    }

    @Test func comparesSchemeAndHostIgnoringCase() throws {
        let url = try #require(URL(string: "Notchly://Settings/general"))
        #expect(links.matches(url))
        #expect(links.pane(from: url) == .general)
    }

    @Test func aLinkWithoutAPaneMatchesButNamesNoPane() throws {
        let url = try #require(URL(string: "notchly://settings"))
        #expect(links.matches(url))
        #expect(links.pane(from: url) == nil)
    }

    @Test func rejectsOtherSchemesAndHosts() throws {
        let otherScheme = try #require(URL(string: "other://settings/general"))
        let otherHost = try #require(URL(string: "notchly://open/general"))
        #expect(!links.matches(otherScheme))
        #expect(links.pane(from: otherScheme) == nil)
        #expect(links.pane(from: otherHost) == nil)
    }

    @Test func customHost() throws {
        let preferences = SettingsURLScheme(scheme: "notchly", host: "preferences")
        let url = try #require(URL(string: "notchly://preferences/general"))
        #expect(preferences.pane(from: url) == .general)
        #expect(preferences.url(for: .general)?.absoluteString == "notchly://preferences/general")
    }
}

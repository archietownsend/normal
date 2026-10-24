import SwiftUI

struct AdultContentToggleView: View {
    @Environment(ScreenTimeService.self) private var screenTimeService
    let defaultKeyType: KeyType?

    var body: some View {
        Section {
            KeyProtectedToggle(
                title: "Block Adult Websites",
                isOn: screenTimeService.isAdultContentBlocked,
                defaultKeyType: defaultKeyType
            ) { screenTimeService.setAdultContentBlocked($0) }
            .accessibilityIdentifier("settings.blockAdultContentToggle")
        } header: {
            Text("Adult Content")
        } footer: {
            Text("Uses Apple's web content filter to block adult websites in Safari and other apps. Stays on independently of blocking. Turning it off requires a key.")
        }
    }
}

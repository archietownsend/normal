import SwiftUI

struct AppInstallToggleView: View {
    @Environment(ScreenTimeService.self) private var screenTimeService
    let defaultKeyType: KeyType?

    var body: some View {
        Section {
            KeyProtectedToggle(
                title: "Block App Installs",
                isOn: screenTimeService.isAppInstallBlocked,
                defaultKeyType: defaultKeyType
            ) { screenTimeService.setAppInstallBlocked($0) }
            .accessibilityIdentifier("settings.blockAppInstallsToggle")
        } header: {
            Text("App Installs")
        } footer: {
            Text("Prevents installing apps from the App Store, so deleted apps can't be downloaded again. Stays on independently of blocking. Turning it off requires a key.")
        }
    }
}

import SwiftUI

struct AppDeleteToggleView: View {
    @Environment(ScreenTimeService.self) private var screenTimeService

    var body: some View {
        Section(
            footer: Text("When enabled, apps cannot be uninstalled from this device.")
        ) {
            KeyProtectedToggle(
                title: "Prevent App Deletion",
                isOn: screenTimeService.isAppDeleteDisabled
            ) { enabled in
                enabled
                    ? screenTimeService.enablePreventAppDelete()
                    : screenTimeService.disablePreventAppDelete()
            }
            .accessibilityIdentifier("home.preventDeleteToggle")
        }
    }
}

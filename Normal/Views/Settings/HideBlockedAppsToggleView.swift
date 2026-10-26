import SwiftUI

struct HideBlockedAppsToggleView: View {
    @Environment(ScreenTimeService.self) private var screenTimeService

    var body: some View {
        Section {
            Toggle(
                "Hide Blocked Apps",
                isOn: Binding(
                    get: { screenTimeService.isHidingBlockedApps },
                    set: { screenTimeService.setHidingBlockedApps($0) }
                )
            )
            .tint(.accentColor)
            .accessibilityIdentifier("settings.hideBlockedAppsToggle")
        } header: {
            Text("Hidden Apps")
        } footer: {
            Text("Blocked apps are removed from the Home Screen, App Library and Search until they're unblocked. Only individually selected apps can be hidden, not categories. Unhidden apps may return to the App Library rather than their original Home Screen position.")
        }
    }
}

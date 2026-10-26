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
            Text("Blocked apps are removed from the Home Screen, App Library and Search until they're unblocked. While on, categories chosen in App Select include each of their installed apps, so every app counts towards the 50 item limit. Update your selection after turning this on. Unhidden apps may return to the App Library rather than their original Home Screen position.")
        }
    }
}

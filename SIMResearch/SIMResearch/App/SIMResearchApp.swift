import SwiftUI

@main
struct SIMResearchApp: App {
    var body: some Scene {
        WindowGroup {
            DeviceNetworkDashboardView(
                viewModel: DeviceNetworkViewModel(
                    provider: DefaultDeviceNetworkInfoProvider()
                )
            )
        }
    }
}

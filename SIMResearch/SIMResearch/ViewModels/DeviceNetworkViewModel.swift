import Foundation

@MainActor
final class DeviceNetworkViewModel: ObservableObject {
    @Published private(set) var snapshot: DeviceNetworkSnapshot?
    @Published private(set) var isLoading = false

    private let provider: DeviceNetworkInfoProviding

    init(provider: DeviceNetworkInfoProviding) {
        self.provider = provider
    }

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        Task { [provider] in
            let snapshot = await provider.fetchSnapshot()
            await MainActor.run {
                self.snapshot = snapshot
                self.isLoading = false
            }
        }
    }
}

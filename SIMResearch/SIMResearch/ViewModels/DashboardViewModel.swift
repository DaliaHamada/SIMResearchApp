import CoreTelephony
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var deviceSnapshot = DeviceInfoSnapshot.placeholder
    @Published private(set) var telephonySnapshot = TelephonyInfoSnapshot.placeholder
    @Published private(set) var lastRefreshDate = Date()

    private let deviceInfoService = DeviceInfoService()
    private let telephonyInfoService = TelephonyInfoService()
    private let telephonyNetworkInfo = CTTelephonyNetworkInfo()
    private var radioObserver: NSObjectProtocol?

    init() {
        refresh()
        configureTelephonyObservers()
    }

    func refresh() {
        deviceSnapshot = deviceInfoService.snapshot()
        telephonySnapshot = telephonyInfoService.snapshot()
        lastRefreshDate = Date()
    }

    private func configureTelephonyObservers() {
        if #available(iOS 12.0, *) {
            telephonyNetworkInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
        } else {
            telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
        }

        radioObserver = NotificationCenter.default.addObserver(
            forName: .CTServiceRadioAccessTechnologyDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let radioObserver {
            NotificationCenter.default.removeObserver(radioObserver)
        }
    }
}

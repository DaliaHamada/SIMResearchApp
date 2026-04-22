import Foundation

/// ViewModel that bridges NetworkInfoService data to SwiftUI views.
@MainActor
final class NetworkInfoViewModel: ObservableObject {

    @Published var cellularRows: [[InfoRow]] = []
    @Published var wifiRows: [InfoRow] = []
    @Published var connectionRows: [InfoRow] = []
    @Published var interfaceRows: [InfoRow] = []

    private let service = NetworkInfoService()

    func refresh() {
        let info = service.collectNetworkInfo()

        cellularRows = info.cellularServices.map { svc in
            [
                InfoRow(label: "Service Key", value: svc.serviceKey),
                InfoRow(label: "Radio Technology", value: svc.humanReadableTechnology,
                        detail: "Raw: \(svc.radioAccessTechnology)")
            ]
        }

        wifiRows = [
            InfoRow(label: "Connected to Wi-Fi", value: info.isConnectedToWiFi ? "Yes" : "No"),
            InfoRow(label: "SSID", value: info.wifiSSID ?? "Unavailable",
                    detail: "Requires 'Access WiFi Information' entitlement + location permission"),
            InfoRow(label: "BSSID", value: info.wifiBSSID ?? "Unavailable",
                    detail: "Requires same entitlements as SSID")
        ]

        connectionRows = [
            InfoRow(label: "IPv4 Address", value: info.currentIPv4Address ?? "N/A"),
            InfoRow(label: "IPv6 Address", value: info.currentIPv6Address ?? "N/A"),
            InfoRow(label: "Expensive Connection", value: info.isExpensiveConnection ? "Yes" : "No",
                    detail: "Cellular or personal hotspot connections are expensive"),
            InfoRow(label: "Constrained Connection", value: info.isConstrainedConnection ? "Yes" : "No",
                    detail: "Low Data Mode is enabled"),
            InfoRow(label: "Supports IPv4", value: info.supportsIPv4 ? "Yes" : "No"),
            InfoRow(label: "Supports IPv6", value: info.supportsIPv6 ? "Yes" : "No")
        ]

        interfaceRows = info.networkInterfaces.map { iface in
            InfoRow(label: "\(iface.name) (\(iface.family))", value: iface.address)
        }
    }
}

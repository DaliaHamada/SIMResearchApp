import Foundation

/// Represents the radio access technology for a cellular service.
struct CellularNetworkInfo: Identifiable {
    let id = UUID()
    let serviceKey: String
    let radioAccessTechnology: String
    let humanReadableTechnology: String
}

/// Aggregated network information including cellular and Wi-Fi data.
struct NetworkInfo {
    let cellularServices: [CellularNetworkInfo]
    let isConnectedToWiFi: Bool
    let wifiSSID: String?
    let wifiBSSID: String?
    let currentIPv4Address: String?
    let currentIPv6Address: String?
    let networkInterfaces: [NetworkInterfaceInfo]
    let isExpensiveConnection: Bool
    let isConstrainedConnection: Bool
    let supportsIPv4: Bool
    let supportsIPv6: Bool
}

/// Represents a single network interface (e.g., en0, pdp_ip0).
struct NetworkInterfaceInfo: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let family: String
}

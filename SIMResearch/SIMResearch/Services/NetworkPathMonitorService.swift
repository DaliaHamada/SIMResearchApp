import Foundation
import Network

@MainActor
final class NetworkPathMonitorService: ObservableObject {
    @Published private(set) var snapshot = NetworkInfoSnapshot.placeholder

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "SIMResearch.NetworkPathMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let snapshot = Self.makeSnapshot(from: path)
            Task { @MainActor in
                self?.snapshot = snapshot
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    static func previewSnapshot() -> NetworkInfoSnapshot {
        NetworkInfoSnapshot(
            summary: "Preview data",
            items: [
                InfoItem(name: "Path status", value: "Satisfied"),
                InfoItem(name: "Interface types in use", value: "Wi-Fi"),
                InfoItem(name: "Is expensive", value: "No"),
                InfoItem(name: "Is constrained", value: "No"),
                InfoItem(name: "Supports DNS", value: "Yes"),
                InfoItem(name: "Supports IPv4", value: "Yes"),
                InfoItem(name: "Supports IPv6", value: "Yes")
            ],
            notes: [
                "The real app uses NWPathMonitor to keep these values up to date.",
                "NWPathMonitor reports interface and path characteristics, not cellular signal strength."
            ]
        )
    }

    private static func makeSnapshot(from path: NWPath) -> NetworkInfoSnapshot {
        let activeInterfaces = interfaceDescriptions(for: path)
        let summary = "\(statusDescription(path.status)) via \(activeInterfaces)"

        let items = [
            InfoItem(name: "Path status", value: statusDescription(path.status)),
            InfoItem(name: "Interface types in use", value: activeInterfaces),
            InfoItem(name: "Uses Wi-Fi", value: booleanDescription(path.usesInterfaceType(.wifi))),
            InfoItem(name: "Uses cellular", value: booleanDescription(path.usesInterfaceType(.cellular))),
            InfoItem(name: "Uses wired Ethernet", value: booleanDescription(path.usesInterfaceType(.wiredEthernet))),
            InfoItem(name: "Uses loopback", value: booleanDescription(path.usesInterfaceType(.loopback))),
            InfoItem(name: "Uses other interface", value: booleanDescription(path.usesInterfaceType(.other))),
            InfoItem(name: "Is expensive", value: booleanDescription(path.isExpensive)),
            InfoItem(name: "Is constrained", value: booleanDescription(path.isConstrained)),
            InfoItem(name: "Supports DNS", value: booleanDescription(path.supportsDNS)),
            InfoItem(name: "Supports IPv4", value: booleanDescription(path.supportsIPv4)),
            InfoItem(name: "Supports IPv6", value: booleanDescription(path.supportsIPv6))
        ]

        let notes = [
            "NWPathMonitor does not reveal SSID, BSSID, IP address ownership, or cellular signal bars in this demo.",
            "A VPN may still appear as Wi-Fi or cellular underneath; public APIs do not expose every transport detail.",
            "No permission prompt is required to observe general path status with the Network framework."
        ]

        return NetworkInfoSnapshot(summary: summary, items: items, notes: notes)
    }

    private static func interfaceDescriptions(for path: NWPath) -> String {
        var names: [String] = []

        if path.usesInterfaceType(.wifi) {
            names.append("Wi-Fi")
        }
        if path.usesInterfaceType(.cellular) {
            names.append("Cellular")
        }
        if path.usesInterfaceType(.wiredEthernet) {
            names.append("Wired Ethernet")
        }
        if path.usesInterfaceType(.loopback) {
            names.append("Loopback")
        }
        if path.usesInterfaceType(.other) {
            names.append("Other")
        }

        return names.isEmpty ? "None" : names.joined(separator: ", ")
    }

    private static func statusDescription(_ status: NWPath.Status) -> String {
        switch status {
        case .satisfied:
            return "Satisfied"
        case .unsatisfied:
            return "Unsatisfied"
        case .requiresConnection:
            return "Requires connection"
        @unknown default:
            return "Unknown future status"
        }
    }

    private static func booleanDescription(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }
}

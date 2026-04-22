//
//  NetworkInfoService.swift
//  Uses the Network framework (NWPathMonitor) to describe the device’s current local network path.
//  This is **not** a substitute for full cellular debug info: it does not return operator name,
//  MCC, or 5G vs LTE except indirectly when the active interface is `cellular`.
//
//  Local network: reading Wi-Fi SSID/BSSID requires the **Access WiFi Information** capability
//  and (often) the **Location** usage description — omitted here to keep the demo app simple.
//

import Foundation
import Network
import CFNetwork

/// Handles starting/stopping a path monitor. Main-thread updates via closure.
final class NetworkPathStore: @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.simresearch.networkpath")

    var onUpdate: ((NWPath) -> Void)?

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.onUpdate?(path)
        }
        monitor.start(queue: queue)
    }

    func currentPath() -> NWPath {
        monitor.currentPath
    }

    deinit {
        monitor.cancel()
    }
}

enum NetworkInfoService {
    // MARK: - Public

    /// Flattens `NWPath` into user-facing rows. Pass `nil` for interfaces before the first path callback.
    static func fieldsFromPath(_ path: NWPath?) -> [DataField] {
        guard let path = path else {
            return [
                DataField(
                    label: "Path status",
                    value: "Waiting for first update…",
                    api: "NWPathMonitor (Network framework)",
                    availability: .deviceOnly
                )
            ]
        }
        return fieldsFromPathReady(path)
    }

    private static func fieldsFromPathReady(_ path: NWPath) -> [DataField] {
        var rows: [DataField] = []

        let statusText: String
        switch path.status {
        case .satisfied: statusText = "Satisfied (reachable)"
        case .unsatisfied: statusText = "Unsatisfied"
        case .requiresConnection: statusText = "Requires connection"
        @unknown default: statusText = "Unknown"
        }
        rows.append(
            DataField(
                label: "Path status",
                value: statusText,
                api: "NWPath.status",
                availability: .generallyAvailable
            )
        )

        rows.append(
            DataField(
                label: "Cellular (interface in use?)",
                value: path.usesInterfaceType(.cellular) ? "This path can use or uses cellular" : "Not using cellular for this path",
                api: "NWPath.usesInterfaceType(.cellular)",
                availability: .generallyAvailable,
                note: "This reflects routing, not a live RAT string (see CoreTelephony for LTE/5G where available)."
            )
        )

        rows.append(
            DataField(
                label: "Expensive (likely cellular or metered)",
                value: path.isExpensive ? "Yes" : "No",
                api: "NWPath.isExpensive",
                availability: .userControllable,
                note: "iOS / carrier policy may mark cellular and some hotspots as expensive."
            )
        )

        if #available(iOS 13.0, *) {
            rows.append(
                DataField(
                    label: "Constrained (Low Data Mode, etc.)",
                    value: path.isConstrained ? "Yes" : "No",
                    api: "NWPath.isConstrained (iOS 13+)",
                    availability: .userControllable
                )
            )
        }

        // List interfaces
        for iface in path.availableInterfaces {
            let t = interfaceTypeName(iface.type)
            rows.append(
                DataField(
                    label: "Interface: \(iface.name)",
                    value: t,
                    api: "NWPathInterface (NWPath.availableInterfaces)",
                    availability: .generallyAvailable
                )
            )
        }
        if path.availableInterfaces.isEmpty {
            rows.append(
                DataField(
                    label: "Interfaces on path",
                    value: "None reported on this path snapshot",
                    api: "NWPath.availableInterfaces",
                    availability: .deviceOnly
                )
            )
        }

        // Wi-Fi: SSID requires entitlement — document only
        rows.append(
            DataField(
                label: "Wi-Fi SSID / BSSID",
                value: "Not read (see README — requires Access WiFi Information + user consent in many cases)",
                api: "SystemConfiguration / CNCopyCurrentNetworkInfo (CaptiveNetwork)",
                availability: .oftenRestricted
            )
        )

        // VPN / HTTP proxy: check common proxy flags via CFNetwork (optional row)
        rows.append(
            DataField(
                label: "System HTTP proxy (from system settings)",
                value: scHTTPProxyString(),
                api: "CFNetworkCopySystemProxySettings (CFNetwork)",
                availability: .userControllable,
                note: "Not a full VPN or DNS picture; some tunnel apps use per-app rules instead."
            )
        )

        return rows
    }

    private static func interfaceTypeName(_ t: NWInterface.InterfaceType) -> String {
        switch t {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular (path layer; use Core Telephony for RAT)"
        case .wiredEthernet: return "Wired"
        case .loopback: return "Loopback"
        case .other: return "Other"
        @unknown default: return "Unknown"
        }
    }

    private static func scHTTPProxyString() -> String {
        guard let dict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return "None or unreadable"
        }
        if (dict["HTTPEnable"] as? Int) == 1, let host = dict["HTTPProxy"] as? String, let port = dict["HTTPPort"] as? Int {
            return "\(host):\(port)"
        }
        return "HTTP proxy not enabled in system settings (or not exposed to apps here)"
    }
}

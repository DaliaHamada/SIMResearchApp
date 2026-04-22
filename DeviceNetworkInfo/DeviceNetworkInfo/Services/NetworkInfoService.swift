import CoreTelephony
import Network
import SystemConfiguration.CaptiveNetwork
import Foundation

/// Service responsible for collecting network-level information.
///
/// APIs used:
/// - `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology` — current RAT per service.
/// - `NWPathMonitor` — connection type, expensive/constrained status, IPv4/IPv6 support.
/// - `getifaddrs()` — enumerate network interfaces and IP addresses.
/// - `CNCopyCurrentNetworkInfo` (deprecated iOS 14+) — SSID/BSSID retrieval
///   (requires location permission + entitlement on iOS 13+; fully deprecated iOS 16+).
///
/// Limitations:
/// - Wi-Fi SSID/BSSID requires:
///   1. The "Access WiFi Information" entitlement.
///   2. Location Services enabled + user authorization (iOS 13+).
///   3. On iOS 14+, use `NEHotspotNetwork.fetchCurrent()` as an alternative.
///   4. On iOS 16+, `CNCopyCurrentNetworkInfo` is fully deprecated.
/// - Cell tower information (LAC, Cell ID) is NOT available via public APIs.
/// - Signal strength (dBm / ASU) is NOT available via public APIs.
final class NetworkInfoService {

    private let networkInfo = CTTelephonyNetworkInfo()

    func collectNetworkInfo() -> NetworkInfo {
        let cellularServices = collectCellularRadioInfo()
        let interfaces = collectNetworkInterfaces()
        let (ipv4, ipv6) = extractPrimaryAddresses(from: interfaces)
        let pathInfo = collectPathMonitorInfo()

        return NetworkInfo(
            cellularServices: cellularServices,
            isConnectedToWiFi: pathInfo.usesWiFi,
            wifiSSID: fetchWiFiSSID(),
            wifiBSSID: fetchWiFiBSSID(),
            currentIPv4Address: ipv4,
            currentIPv6Address: ipv6,
            networkInterfaces: interfaces,
            isExpensiveConnection: pathInfo.isExpensive,
            isConstrainedConnection: pathInfo.isConstrained,
            supportsIPv4: pathInfo.supportsIPv4,
            supportsIPv6: pathInfo.supportsIPv6
        )
    }

    // MARK: - Cellular Radio Access Technology

    private func collectCellularRadioInfo() -> [CellularNetworkInfo] {
        guard let radioDict = networkInfo.serviceCurrentRadioAccessTechnology else {
            return []
        }

        return radioDict.map { (key, value) in
            CellularNetworkInfo(
                serviceKey: key,
                radioAccessTechnology: value,
                humanReadableTechnology: humanReadableRAT(value)
            )
        }.sorted { $0.serviceKey < $1.serviceKey }
    }

    /// Maps CTRadioAccessTechnology constants to human-readable names.
    private func humanReadableRAT(_ rat: String) -> String {
        switch rat {
        case CTRadioAccessTechnologyGPRS: return "GPRS (2G)"
        case CTRadioAccessTechnologyEdge: return "EDGE (2G)"
        case CTRadioAccessTechnologyWCDMA: return "WCDMA (3G)"
        case CTRadioAccessTechnologyHSDPA: return "HSDPA (3G)"
        case CTRadioAccessTechnologyHSUPA: return "HSUPA (3G)"
        case CTRadioAccessTechnologyCDMA1x: return "CDMA 1x (2G)"
        case CTRadioAccessTechnologyCDMAEVDORev0: return "EVDO Rev. 0 (3G)"
        case CTRadioAccessTechnologyCDMAEVDORevA: return "EVDO Rev. A (3G)"
        case CTRadioAccessTechnologyCDMAEVDORevB: return "EVDO Rev. B (3G)"
        case CTRadioAccessTechnologyeHRPD: return "eHRPD (3G)"
        case CTRadioAccessTechnologyLTE: return "LTE (4G)"
        default:
            if #available(iOS 14.1, *) {
                if rat == CTRadioAccessTechnologyNRNSA { return "5G NR NSA" }
                if rat == CTRadioAccessTechnologyNR { return "5G NR" }
            }
            return rat
        }
    }

    // MARK: - Wi-Fi Info

    /// Attempts to fetch the current Wi-Fi SSID.
    /// Requires "Access WiFi Information" entitlement and location authorization on iOS 13+.
    /// Returns nil if unavailable.
    private func fetchWiFiSSID() -> String? {
        #if !targetEnvironment(simulator)
        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                   let ssid = info[kCNNetworkInfoKeySSID as String] as? String {
                    return ssid
                }
            }
        }
        #endif
        return nil
    }

    /// Attempts to fetch the current Wi-Fi BSSID.
    private func fetchWiFiBSSID() -> String? {
        #if !targetEnvironment(simulator)
        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                   let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String {
                    return bssid
                }
            }
        }
        #endif
        return nil
    }

    // MARK: - Network Interfaces (getifaddrs)

    /// Enumerates all active network interfaces and their IP addresses using getifaddrs().
    private func collectNetworkInterfaces() -> [NetworkInterfaceInfo] {
        var interfaces: [NetworkInterfaceInfo] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return interfaces
        }

        defer { freeifaddrs(ifaddr) }

        var current: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = current {
            let flags = Int32(addr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0

            if isUp && isRunning, let sockaddr = addr.pointee.ifa_addr {
                let family = sockaddr.pointee.sa_family
                if family == UInt8(AF_INET) || family == UInt8(AF_INET6) {
                    let name = String(cString: addr.pointee.ifa_name)
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

                    if getnameinfo(
                        sockaddr,
                        socklen_t(sockaddr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil, 0,
                        NI_NUMERICHOST
                    ) == 0 {
                        let address = String(cString: hostname)
                        let familyName = family == UInt8(AF_INET) ? "IPv4" : "IPv6"
                        interfaces.append(NetworkInterfaceInfo(
                            name: name,
                            address: address,
                            family: familyName
                        ))
                    }
                }
            }
            current = addr.pointee.ifa_next
        }

        return interfaces
    }

    private func extractPrimaryAddresses(from interfaces: [NetworkInterfaceInfo]) -> (String?, String?) {
        let ipv4 = interfaces.first { $0.family == "IPv4" && ($0.name == "en0" || $0.name.hasPrefix("pdp_ip")) }?.address
        let ipv6 = interfaces.first { $0.family == "IPv6" && ($0.name == "en0" || $0.name.hasPrefix("pdp_ip")) }?.address
        return (ipv4, ipv6)
    }

    // MARK: - NWPathMonitor Snapshot

    private struct PathInfo {
        let usesWiFi: Bool
        let isExpensive: Bool
        let isConstrained: Bool
        let supportsIPv4: Bool
        let supportsIPv6: Bool
    }

    /// Takes a synchronous snapshot of the current NWPath status.
    private func collectPathMonitorInfo() -> PathInfo {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var result = PathInfo(
            usesWiFi: false,
            isExpensive: false,
            isConstrained: false,
            supportsIPv4: false,
            supportsIPv6: false
        )

        monitor.pathUpdateHandler = { path in
            result = PathInfo(
                usesWiFi: path.usesInterfaceType(.wifi),
                isExpensive: path.isExpensive,
                isConstrained: path.isConstrained,
                supportsIPv4: path.supportsIPv4,
                supportsIPv6: path.supportsIPv6
            )
            semaphore.signal()
        }

        let queue = DispatchQueue(label: "com.devicenetworkinfo.pathmonitor")
        monitor.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + 2)
        monitor.cancel()

        return result
    }
}

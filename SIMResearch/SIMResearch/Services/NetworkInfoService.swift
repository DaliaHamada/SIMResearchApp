//
//  NetworkInfoService.swift
//  SIMResearch
//
//  Wraps `NWPathMonitor` from Apple's Network framework.
//

import Foundation
import Network

/// Observes the system-wide network path and forwards `NetworkSnapshot`
/// updates to a single subscriber.
final class NetworkInfoService {

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "SIMResearch.NetworkInfoService")
    private var isMonitoring = false

    init() {
        self.monitor = NWPathMonitor()
    }

    deinit { monitor.cancel() }

    /// Starts forwarding updates. Calling twice is a no-op.
    /// Updates are dispatched on a private serial queue – callers
    /// should hop to the main thread before mutating UI state.
    func startMonitoring(handler: @escaping (NetworkSnapshot) -> Void) {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitor.pathUpdateHandler = { path in
            handler(Self.snapshot(from: path))
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
        isMonitoring = false
    }

    /// Returns the latest snapshot reported by the monitor (may be the
    /// initial / unknown value if `startMonitoring` has not yet been
    /// called).
    func currentSnapshot() -> NetworkSnapshot {
        Self.snapshot(from: monitor.currentPath)
    }

    // MARK: - Helpers

    private static func snapshot(from path: NWPath) -> NetworkSnapshot {
        let primary: NetworkInterface = {
            if path.usesInterfaceType(.wifi)         { return .wifi }
            if path.usesInterfaceType(.cellular)     { return .cellular }
            if path.usesInterfaceType(.wiredEthernet) { return .wired }
            if path.usesInterfaceType(.loopback)     { return .loopback }
            if path.usesInterfaceType(.other)        { return .other }
            return .none
        }()

        let available = path.availableInterfaces.map { NetworkInterface($0.type) }

        return NetworkSnapshot(
            status: NetworkStatus(path.status),
            primaryInterface: primary,
            availableInterfaces: available,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            supportsIPv4: path.supportsIPv4,
            supportsIPv6: path.supportsIPv6,
            supportsDNS: path.supportsDNS
        )
    }
}

//
//  NetworkInfo.swift
//  SIMResearch
//
//  A snapshot of the device-wide network reachability status as
//  reported by Apple's `Network` framework (`NWPathMonitor`).
//

import Foundation
import Network

/// High-level connectivity status.
enum NetworkStatus: String, Equatable {
    case satisfied      = "Connected"
    case unsatisfied    = "Disconnected"
    case requiresConnection = "Requires connection"
    case unknown        = "Unknown"

    init(_ status: NWPath.Status) {
        switch status {
        case .satisfied:           self = .satisfied
        case .unsatisfied:         self = .unsatisfied
        case .requiresConnection:  self = .requiresConnection
        @unknown default:          self = .unknown
        }
    }
}

/// Categorical interface that is currently used.
enum NetworkInterface: String, Equatable, CaseIterable {
    case wifi       = "Wi-Fi"
    case cellular   = "Cellular"
    case wired      = "Wired Ethernet"
    case loopback   = "Loopback"
    case other      = "Other"
    case none       = "None"

    init(_ type: NWInterface.InterfaceType?) {
        switch type {
        case .wifi:     self = .wifi
        case .cellular: self = .cellular
        case .wiredEthernet: self = .wired
        case .loopback: self = .loopback
        case .other:    self = .other
        default:        self = .none
        }
    }
}

/// Aggregated network reachability snapshot.
struct NetworkSnapshot: Equatable {
    let status: NetworkStatus
    let primaryInterface: NetworkInterface
    let availableInterfaces: [NetworkInterface]
    let isExpensive: Bool
    let isConstrained: Bool
    let supportsIPv4: Bool
    let supportsIPv6: Bool
    let supportsDNS: Bool

    static let unknown = NetworkSnapshot(
        status: .unknown,
        primaryInterface: .none,
        availableInterfaces: [],
        isExpensive: false,
        isConstrained: false,
        supportsIPv4: false,
        supportsIPv6: false,
        supportsDNS: false
    )
}

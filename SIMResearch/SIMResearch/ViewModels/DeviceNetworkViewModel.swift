//
//  DeviceNetworkViewModel.swift
//  Fetches device, cellular, and local-network path data. Refreshing re-reads static info and
//  keeps the path monitor in sync. No private APIs, no entitlements for Wi-Fi SSID.
//

import Foundation
import CoreTelephony
import Network

@MainActor
final class DeviceNetworkViewModel: ObservableObject {
    @Published private(set) var deviceFields: [DataField] = []
    @Published private(set) var cellularSummary: CellularSummary
    @Published private(set) var networkFields: [DataField] = []
    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdated: Date = .distantPast
    @Published var currentPath: NWPath?

    private var pathStore = NetworkPathStore()
    /// Kept alive so `subscriberCellularProviderDidUpdateNotifier` continues to work for the app’s lifetime.
    private let telephony = CTTelephonyNetworkInfo()

    init() {
        cellularSummary = CellularSummary(
            slotCount: 0,
            interpretation: "Loading…",
            systemWarning: nil,
            slots: [],
            serviceRadioTechnologies: [:]
        )
        pathStore.onUpdate = { [weak self] path in
            Task { @MainActor in
                self?.currentPath = path
                self?.networkFields = NetworkInfoService.fieldsFromPath(path)
            }
        }
        pathStore.start()
        let initialPath = pathStore.currentPath()
        currentPath = initialPath

        if #available(iOS 12.0, *) {
            telephony.subscriberCellularProviderDidUpdateNotifier = { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
        }

        refresh()
    }

    func refresh() {
        lastError = nil
        deviceFields = DeviceInfoService.makeDeviceSection()
        cellularSummary = CellularInfoService.loadSummary()
        if currentPath == nil { currentPath = pathStore.currentPath() }
        networkFields = NetworkInfoService.fieldsFromPath(pathStore.currentPath())
        lastUpdated = Date()
    }
}

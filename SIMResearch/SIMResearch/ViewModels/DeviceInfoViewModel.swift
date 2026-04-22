//
//  DeviceInfoViewModel.swift
//  SIMResearch
//

import Foundation
import Combine

/// Drives the Device Info screen.
@MainActor
final class DeviceInfoViewModel: ObservableObject {
    @Published private(set) var info: DeviceInfo
    @Published private(set) var lastUpdated: Date

    private let service: DeviceInfoService

    init(service: DeviceInfoService = DeviceInfoService()) {
        self.service = service
        self.info = service.currentSnapshot()
        self.lastUpdated = Date()
    }

    func refresh() {
        info = service.currentSnapshot()
        lastUpdated = Date()
    }
}

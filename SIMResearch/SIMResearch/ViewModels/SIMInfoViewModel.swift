//
//  SIMInfoViewModel.swift
//  SIMResearch
//

import Foundation
import Combine

/// Drives the SIM / Carrier screen. Subscribes to CoreTelephony change
/// notifications so the UI updates if the user toggles a SIM line at
/// runtime.
@MainActor
final class SIMInfoViewModel: ObservableObject {
    @Published private(set) var snapshot: SIMSnapshot
    @Published private(set) var lastUpdated: Date

    private let service: SIMInfoService

    init(service: SIMInfoService = SIMInfoService()) {
        self.service = service
        self.snapshot = service.currentSnapshot()
        self.lastUpdated = Date()
        startObserving()
    }

    func refresh() {
        snapshot = service.currentSnapshot()
        lastUpdated = Date()
    }

    private func startObserving() {
        service.startObserving { [weak self] newSnapshot in
            // CoreTelephony invokes the notifier on a private serial
            // queue – marshal back to the main actor before mutating
            // published state.
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.snapshot = newSnapshot
                self.lastUpdated = Date()
            }
        }
    }
}

//
//  NetworkInfoViewModel.swift
//  SIMResearch
//

import Foundation
import Combine

@MainActor
final class NetworkInfoViewModel: ObservableObject {
    @Published private(set) var snapshot: NetworkSnapshot
    @Published private(set) var lastUpdated: Date

    private let service: NetworkInfoService

    init(service: NetworkInfoService = NetworkInfoService()) {
        self.service = service
        self.snapshot = service.currentSnapshot()
        self.lastUpdated = Date()
        start()
    }

    private func start() {
        service.startMonitoring { [weak self] newSnapshot in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.snapshot = newSnapshot
                self.lastUpdated = Date()
            }
        }
    }

    func refresh() {
        snapshot = service.currentSnapshot()
        lastUpdated = Date()
    }
}

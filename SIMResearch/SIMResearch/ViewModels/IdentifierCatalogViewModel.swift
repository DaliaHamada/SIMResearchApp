//
//  IdentifierCatalogViewModel.swift
//  SIMResearch
//

import Foundation
import SwiftUI

@MainActor
final class IdentifierCatalogViewModel: ObservableObject {
    @Published private(set) var entries: [IdentifierLifecycleEntry]
    @Published private(set) var lastUpdated: Date

    private let service: IdentifierCatalogService

    init(service: IdentifierCatalogService? = nil) {
        let resolved = service ?? IdentifierCatalogService()
        self.service = resolved
        self.entries = resolved.currentCatalog()
        self.lastUpdated = Date()
    }

    func refresh() {
        entries = service.currentCatalog()
        lastUpdated = Date()
    }
}

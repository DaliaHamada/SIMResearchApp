//
//  SIMResearchApp.swift
//  SIMResearch
//
//  Created by Dalia Hamada on 16/10/2025.
//

import SwiftUI

@main
struct SIMResearchApp: App {
    var body: some Scene {
        WindowGroup {
            DeviceNetworkDashboard()
        }
    }
}

// MARK: - Optional legacy screen (kept for comparison with earlier carrier-only UI)

struct LegacyCarrierTabsView: View {
    var body: some View {
        TabView {
            CarrierInfoView()
                .tabItem {
                    Label("Carrier (legacy UI)", systemImage: "antenna.radiowaves.left.and.right")
                }

            ResearchSummaryView()
                .tabItem {
                    Label("R&D Summary", systemImage: "doc.text.magnifyingglass")
                }
        }
    }
}

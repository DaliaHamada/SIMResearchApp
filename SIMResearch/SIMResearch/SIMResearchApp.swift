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
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            CarrierInfoView()
                .tabItem {
                    Label("Carrier Info", systemImage: "antenna.radiowaves.left.and.right")
                }
            
            ResearchSummaryView()
                .tabItem {
                    Label("Research", systemImage: "doc.text.magnifyingglass")
                }
        }
    }
}

//
//  SIMResearchApp.swift
//  SIMResearch
//
//  Demo app that surfaces every public iOS API related to the device,
//  the SIM/eSIM/carrier configuration and the network reachability
//  status. Uses SwiftUI throughout and only public Apple APIs.
//

import SwiftUI

@main
struct SIMResearchApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

/// Root navigation – four tabs, one per concern.
struct RootTabView: View {
    var body: some View {
        TabView {
            DeviceInfoView()
                .tabItem {
                    Label("Device", systemImage: "iphone")
                }
            SIMInfoView()
                .tabItem {
                    Label("SIM / Carrier", systemImage: "simcard.2.fill")
                }
            NetworkInfoView()
                .tabItem {
                    Label("Network", systemImage: "wifi")
                }
            LimitationsView()
                .tabItem {
                    Label("Limitations", systemImage: "info.circle")
                }
        }
    }
}

#Preview {
    RootTabView()
}

//
//  ResearchSummaryView.swift
//  SIMResearch
//
//  Created by Dalia Hamada on 16/10/2025.
//

import SwiftUI

struct ResearchSummaryView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("✅ What Works")) {
                    FeatureRow(
                        title: "Get SIM Operator",
                        status: .works,
                        description: "Can retrieve carrier name (e.g., Vodafone, Orange) via CoreTelephony"
                    )
                    
                    FeatureRow(
                        title: "Get Country & Network Codes",
                        status: .works,
                        description: "MCC, MNC, and ISO country codes available"
                    )
                    
                    FeatureRow(
                        title: "SMS Sender Number",
                        status: .partial,
                        description: "Only in SMS Filter Extension, not in main app"
                    )
                }
                
                Section(header: Text("❌ What Doesn't Work")) {
                    FeatureRow(
                        title: "Detect SIM Count",
                        status: .notPossible,
                        description: "No API to directly count physical or eSIMs"
                    )
                    
                    FeatureRow(
                        title: "Get Phone Number",
                        status: .notPossible,
                        description: "Privacy restrictions prevent access to device phone number"
                    )
                    
                    FeatureRow(
                        title: "SMS Sender Name",
                        status: .notPossible,
                        description: "Contact names not exposed to SMS extensions"
                    )
                    
                    FeatureRow(
                        title: "Detect Which SIM Received SMS",
                        status: .notPossible,
                        description: "SIM slot information not provided in iOS APIs"
                    )
                    
                    FeatureRow(
                        title: "Detect SIM Removal/Change",
                        status: .notPossible,
                        description: "No notifications or callbacks for SIM changes"
                    )
                }
            }
            .navigationTitle("R&D Summary")
        }
    }
}

enum FeatureStatus {
    case works
    case partial
    case notPossible
    
    var icon: String {
        switch self {
        case .works: return "checkmark.circle.fill"
        case .partial: return "exclamationmark.triangle.fill"
        case .notPossible: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .works: return .green
        case .partial: return .orange
        case .notPossible: return .red
        }
    }
}

struct FeatureRow: View {
    let title: String
    let status: FeatureStatus
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

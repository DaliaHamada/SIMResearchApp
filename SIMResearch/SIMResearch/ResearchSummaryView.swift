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
                Section {
                    Text("Based on official Apple Documentation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Label("Available (iOS 15 and earlier)", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)) {
                    FeatureRow(
                        title: "Active Cellular Slot Count",
                        status: .worksLegacy,
                        description: "serviceSubscriberCellularProviders.count returns number of active slots",
                        apiReference: "CTTelephonyNetworkInfo"
                    )
                    
                    FeatureRow(
                        title: "Carrier Name",
                        status: .worksLegacy,
                        description: "CTCarrier.carrierName (e.g., 'Vodafone', 'Orange')",
                        apiReference: "CTCarrier.carrierName"
                    )
                    
                    FeatureRow(
                        title: "Country Codes",
                        status: .worksLegacy,
                        description: "ISO country code, MCC, MNC available",
                        apiReference: "CTCarrier properties"
                    )
                    
                    FeatureRow(
                        title: "VoIP Support Detection",
                        status: .worksLegacy,
                        description: "Check if carrier allows VoIP calls",
                        apiReference: "CTCarrier.allowsVOIP"
                    )
                    
                    FeatureRow(
                        title: "Carrier Change Notification",
                        status: .partial,
                        description: "Detects changes only while app is running",
                        apiReference: "subscriberCellularProviderDidUpdateNotifier"
                    )
                }
                
                Section(header: Label("Deprecated (iOS 16+)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)) {
                    FeatureRow(
                        title: "CTCarrier API",
                        status: .deprecated,
                        description: "All CTCarrier properties return nil starting iOS 16.4. No replacement provided.",
                        apiReference: "Apple Developer Forums"
                    )
                }
                
                Section(header: Label("Not Possible", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)) {
                    FeatureRow(
                        title: "Phone Number from SIM",
                        status: .notPossible,
                        description: "Privacy restrictions prevent API access",
                        apiReference: "Apple Privacy Guidelines"
                    )
                    
                    FeatureRow(
                        title: "SMS Sender Detection",
                        status: .notPossible,
                        description: "Cannot read incoming SMS or sender info in regular apps",
                        apiReference: "SMS Filtering Extension only"
                    )
                    
                    FeatureRow(
                        title: "Distinguish SIM Types",
                        status: .notPossible,
                        description: "Cannot differentiate physical SIM from eSIM",
                        apiReference: "No API available"
                    )
                    
                    FeatureRow(
                        title: "Detect Inactive eSIM",
                        status: .notPossible,
                        description: "Only active slots are visible to apps",
                        apiReference: "Settings app only"
                    )
                    
                    FeatureRow(
                        title: "Which SIM Received SMS/Call",
                        status: .notPossible,
                        description: "Slot information not exposed to developers",
                        apiReference: "iOS 17 user feature only"
                    )
                    
                    FeatureRow(
                        title: "SIM Removal Detection",
                        status: .notPossible,
                        description: "No system notifications or callbacks available",
                        apiReference: "Privacy restriction"
                    )
                    
                    FeatureRow(
                        title: "Unique SIM Identifiers",
                        status: .notPossible,
                        description: "ICCID, IMSI not accessible for privacy/security",
                        apiReference: "Core Telephony limitations"
                    )
                }
                
                Section(header: Text("References")) {
                    Link(destination: URL(string: "https://developer.apple.com/documentation/coretelephony")!) {
                        ReferenceRow(title: "Core Telephony Framework", subtitle: "Apple Developer Documentation")
                    }
                    
                    Link(destination: URL(string: "https://developer.apple.com/forums/thread/714876")!) {
                        ReferenceRow(title: "CTCarrier Deprecation", subtitle: "Apple Developer Forums")
                    }
                    
                    Link(destination: URL(string: "https://support.apple.com/en-us/118669")!) {
                        ReferenceRow(title: "About eSIM on iPhone", subtitle: "Apple Support")
                    }
                    
                    Link(destination: URL(string: "https://developer.apple.com/app-store/user-privacy-and-data-use/")!) {
                        ReferenceRow(title: "Privacy Guidelines", subtitle: "Apple Developer")
                    }
                }
            }
            .navigationTitle("Research Summary")
        }
    }
}

enum FeatureStatus {
    case worksLegacy    // Works on iOS 15 and below
    case partial        // Limited functionality
    case deprecated     // Officially deprecated
    case notPossible    // Not available due to privacy/security
    
    var icon: String {
        switch self {
        case .worksLegacy: return "checkmark.circle.fill"
        case .partial: return "exclamationmark.triangle.fill"
        case .deprecated: return "xmark.octagon.fill"
        case .notPossible: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .worksLegacy: return .green
        case .partial: return .orange
        case .deprecated: return .orange
        case .notPossible: return .red
        }
    }
}

struct FeatureRow: View {
    let title: String
    let status: FeatureStatus
    let description: String
    let apiReference: String
    
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
                
                Text("API: \(apiReference)")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ReferenceRow: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .foregroundColor(.blue)
        }
    }
}

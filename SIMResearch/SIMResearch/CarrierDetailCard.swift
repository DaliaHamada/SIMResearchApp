//
//  CarrierDetailCard.swift
//  SIMResearch
//
//  Created by Dalia Hamada on 19/10/2025.
//

import SwiftUI

struct CarrierDetailCard: View {
    let carrier: CarrierDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: carrier.isDeprecated ? "exclamationmark.triangle.fill" : "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundColor(carrier.isDeprecated ? .orange : .blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(carrier.displayName)
                        .font(.headline)
                    Text("Slot ID: \(carrier.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: carrier.statusDescription, isDeprecated: carrier.isDeprecated)
            }
            
            if carrier.isDeprecated {
                DeprecationWarning()
            } else if carrier.carrierName != nil {
                Divider()
                
                VStack(spacing: 8) {
                    DetailRow(
                        label: "Carrier Name",
                        value: carrier.carrierName ?? "N/A",
                        icon: "antenna.radiowaves.left.and.right"
                    )
                    DetailRow(
                        label: "Country",
                        value: carrier.fullCountryName,
                        icon: "flag.fill"
                    )
                    DetailRow(
                        label: "ISO Country Code",
                        value: carrier.countryCode ?? "N/A",
                        icon: "globe"
                    )
                    DetailRow(
                        label: "MCC (Mobile Country Code)",
                        value: carrier.mobileCountryCode ?? "N/A",
                        icon: "number"
                    )
                    DetailRow(
                        label: "MNC (Mobile Network Code)",
                        value: carrier.mobileNetworkCode ?? "N/A",
                        icon: "network"
                    )
                    DetailRow(
                        label: "VoIP Allowed",
                        value: carrier.allowsVOIP ? "Yes" : "No",
                        icon: "phone.circle.fill"
                    )
                }
            } else {
                Text("No active cellular service detected on this slot")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct StatusBadge: View {
    let status: String
    let isDeprecated: Bool
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isDeprecated ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
            .foregroundColor(isDeprecated ? .orange : .green)
            .cornerRadius(8)
    }
}

struct DeprecationWarning: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Deprecated")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("CTCarrier properties return nil in iOS 16+. Apple provides no replacement for carrier information access.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

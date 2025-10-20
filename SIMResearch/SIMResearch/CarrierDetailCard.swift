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
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(carrier.displayName)
                        .font(.headline)
                    Text("SIM ID: \(carrier.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if carrier.allowsVOIP {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            VStack(spacing: 8) {
                DetailRow(label: "Country", value: carrier.fullCountryName, icon: "flag.fill")
                DetailRow(label: "Country Code", value: carrier.countryCode, icon: "globe")
                DetailRow(label: "Mobile Country Code", value: carrier.mobileCountryCode, icon: "number")
                DetailRow(label: "Mobile Network Code", value: carrier.mobileNetworkCode, icon: "network")
                DetailRow(label: "VoIP Support", value: carrier.allowsVOIP ? "Yes" : "No", icon: "phone.circle.fill")
            }
        }
        .padding()
        .background(Color(.gray).opacity(0.2))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

//
//  CarrierInfoView.swift
//  SIMResearch
//
//  Created by Dalia Hamada on 16/10/2025.
//

import SwiftUI

struct CarrierInfoView: View {
    @StateObject private var viewModel = CarrierInfoViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading carrier information...")
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.fetchCarrierInfo()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // iOS Version Warning
                            if #available(iOS 16.0, *) {
                                iOS16WarningCard()
                            }
                            
                            // SIM Count Card
                            InfoCardView(
                                title: "Active Cellular Slots",
                                value: "\(viewModel.carrierCount)",
                                subtitle: viewModel.deviceDescription,
                                icon: "simcard.fill",
                                color: .blue
                            )
                            
                            // Carrier Details
                            ForEach(viewModel.carriers) { carrier in
                                CarrierDetailCard(carrier: carrier)
                            }
                            
                            // Limitations Card
                            LimitationsCard()
                            
                            // Footer
                            VStack(spacing: 4) {
                                Text("Last updated: \(viewModel.lastUpdated, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("iOS \(UIDevice.current.systemVersion)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("SIM & Carrier Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.fetchCarrierInfo()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Button(action: retryAction) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct iOS16WarningCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("iOS 16+ Limitation")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text("CTCarrier API is deprecated. Carrier information returns nil with no replacement available.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct LimitationsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("What This App Cannot Do")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                LimitationRow(text: "Cannot distinguish physical SIM from eSIM")
                LimitationRow(text: "Cannot detect inactive eSIM profiles")
                LimitationRow(text: "Cannot retrieve phone number from SIM")
                LimitationRow(text: "Cannot detect SIM removal/insertion")
                LimitationRow(text: "Cannot access SMS sender information")
                LimitationRow(text: "Cannot identify which SIM received calls/SMS")
            }
            
            Text("These limitations are due to iOS privacy and security restrictions.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct LimitationRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(.red)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

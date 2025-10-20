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
                Color(.gray).opacity(0.2)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading carrier information...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Button(action: {
                            viewModel.fetchCarrierInfo()
                        }) {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            InfoCardView(
                                title: "Detected Carriers",
                                value: "\(viewModel.carrierCount)",
                                subtitle: viewModel.hasMultipleSIMs ? "Dual-SIM Device" : "Single SIM",
                                icon: "sim.fill",
                                color: .blue
                            )
                            
                            ForEach(viewModel.carriers) { carrier in
                                CarrierDetailCard(carrier: carrier)
                            }
                            
                            Text("Last updated: \(viewModel.lastUpdated, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Carrier Info")
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

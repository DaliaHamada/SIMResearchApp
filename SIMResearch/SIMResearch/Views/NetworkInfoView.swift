//
//  NetworkInfoView.swift
//  SIMResearch
//

import SwiftUI

struct NetworkInfoView: View {
    @StateObject private var viewModel = NetworkInfoViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusSection
                    interfacesSection
                    flagsSection

                    Text("Last refreshed \(viewModel.lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Network")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")
                }
            }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        SectionCard("Connectivity", systemImage: "wifi", tint: statusTint) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.snapshot.status.rawValue)
                        .font(.title2.weight(.semibold))
                    Text("Primary: \(viewModel.snapshot.primaryInterface.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: statusIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(statusTint)
            }
        }
    }

    private var interfacesSection: some View {
        SectionCard("Available Interfaces", systemImage: "rectangle.stack", tint: .indigo) {
            if viewModel.snapshot.availableInterfaces.isEmpty {
                Text("No interfaces are currently available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(viewModel.snapshot.availableInterfaces.enumerated()), id: \.offset) { _, iface in
                    InfoRow(
                        label: iface.rawValue,
                        value: iface == viewModel.snapshot.primaryInterface ? "Primary" : "Available",
                        caption: "NWPath.availableInterfaces",
                        systemImage: icon(for: iface)
                    )
                }
            }
        }
    }

    private var flagsSection: some View {
        SectionCard("Path Flags", systemImage: "flag.checkered", tint: .green) {
            InfoRow(
                label: "Expensive",
                value: viewModel.snapshot.isExpensive ? "Yes" : "No",
                caption: "NWPath.isExpensive (cellular / personal hotspot)",
                systemImage: "dollarsign.circle"
            )
            InfoRow(
                label: "Constrained",
                value: viewModel.snapshot.isConstrained ? "Yes" : "No",
                caption: "NWPath.isConstrained (Low Data Mode)",
                systemImage: "tortoise"
            )
            InfoRow(
                label: "IPv4",
                value: viewModel.snapshot.supportsIPv4 ? "Supported" : "Not supported",
                caption: "NWPath.supportsIPv4",
                systemImage: "4.circle"
            )
            InfoRow(
                label: "IPv6",
                value: viewModel.snapshot.supportsIPv6 ? "Supported" : "Not supported",
                caption: "NWPath.supportsIPv6",
                systemImage: "6.circle"
            )
            InfoRow(
                label: "DNS",
                value: viewModel.snapshot.supportsDNS ? "Supported" : "Not supported",
                caption: "NWPath.supportsDNS",
                systemImage: "magnifyingglass"
            )
        }
    }

    // MARK: - Style helpers

    private var statusTint: Color {
        switch viewModel.snapshot.status {
        case .satisfied: return .green
        case .unsatisfied: return .red
        case .requiresConnection: return .orange
        case .unknown: return .gray
        }
    }

    private var statusIcon: String {
        switch viewModel.snapshot.status {
        case .satisfied: return "checkmark.seal.fill"
        case .unsatisfied: return "xmark.octagon.fill"
        case .requiresConnection: return "hourglass"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private func icon(for iface: NetworkInterface) -> String {
        switch iface {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wired: return "cable.connector"
        case .loopback: return "arrow.triangle.2.circlepath"
        case .other: return "questionmark.circle"
        case .none: return "minus.circle"
        }
    }
}

#Preview {
    NetworkInfoView()
}

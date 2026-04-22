//
//  DeviceNetworkDashboard.swift
//  Main screen: three sections (Device, SIM & carrier, Network) with refresh.
//

import SwiftUI

struct DeviceNetworkDashboard: View {
    @StateObject private var viewModel = DeviceNetworkViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let err = viewModel.lastError {
                        Text(err)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }

                    DataFieldListSection(
                        title: "Device",
                        systemImage: "iphone",
                        fields: viewModel.deviceFields,
                        footer: "IDFV is the only per-device id third-party apps can read. Serial number, UDID, and IMEI are not available in public App Store APIs."
                    )

                    cellularBlock

                    DataFieldListSection(
                        title: "Local network path",
                        systemImage: "network",
                        fields: viewModel.networkFields,
                        footer: "NWPath shows routing and interfaces, not the cellular generation name (5G) — that comes from Core Telephony for cellular radio, when available."
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Device & Network")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(verbatim: "Updated \(viewModel.lastUpdated.formatted(.dateTime.day().month().year().hour().minute().second()))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Cellular block (summary + one card per line)

    @ViewBuilder
    private var cellularBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("SIM & carrier (Core Telephony)", systemImage: "sim.fill")
                .font(.headline)

            Text(viewModel.cellularSummary.interpretation)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let w = viewModel.cellularSummary.systemWarning {
                Text(w)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            // Raw RAT map (all services)
            if !viewModel.cellularSummary.serviceRadioTechnologies.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Service → radio (raw)")
                        .font(.subheadline)
                    ForEach(
                        viewModel.cellularSummary.serviceRadioTechnologies.keys.sorted(),
                        id: \.self
                    ) { k in
                        if let v = viewModel.cellularSummary.serviceRadioTechnologies[k] {
                            HStack {
                                Text(k)
                                    .font(.caption2)
                                    .lineLimit(2)
                                Spacer()
                                Text(v)
                                    .font(.caption2)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(.tertiarySystemBackground)))
            }

            if viewModel.cellularSummary.slots.isEmpty {
                Text("No CTCarrier data (Simulator, no SIM, or no active plan). Run on a physical iPhone with cellular service for full data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
            } else {
                ForEach(viewModel.cellularSummary.slots) { slot in
                    slotCard(slot)
                }
            }
        }
    }

    private func slotCard(_ slot: CellularSlotInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Line / subscription")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if slot.isDataPreferred {
                    Text("Cellular data line")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                }
            }
            .padding([.top, .horizontal], 10)

            ForEach(Array(slot.fields.enumerated()), id: \.element.id) { index, f in
                DataFieldRow(field: f)
                if index < slot.fields.count - 1 {
                    Divider()
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    DeviceNetworkDashboard()
}

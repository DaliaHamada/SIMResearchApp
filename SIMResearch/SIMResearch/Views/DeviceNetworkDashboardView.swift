import SwiftUI

struct DeviceNetworkDashboardView: View {
    @StateObject var viewModel: DeviceNetworkViewModel

    init(viewModel: DeviceNetworkViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = viewModel.snapshot {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionCard(title: "Device Info", systemImage: "iphone") {
                                ForEach(snapshot.deviceInfo) { field in
                                    InfoFieldRow(field: field)
                                    if field.id != snapshot.deviceInfo.last?.id {
                                        Divider()
                                    }
                                }
                            }

                            SectionCard(title: "SIM / Carrier Info", systemImage: "simcard") {
                                simSummaryView(snapshot.simSummary)

                                if snapshot.carrierInfo.isEmpty {
                                    Text("No active carrier records were returned by CoreTelephony.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("SIM Type Classification (Physical SIM vs eSIM): Not available via public iOS APIs.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, 6)
                                    ForEach(snapshot.carrierInfo) { carrier in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Service Identifier: \(carrier.serviceIdentifier)")
                                                .font(.subheadline.weight(.semibold))

                                            ForEach(carrier.fields) { field in
                                                InfoFieldRow(field: field)
                                                if field.id != carrier.fields.last?.id {
                                                    Divider()
                                                }
                                            }
                                        }

                                        if carrier.id != snapshot.carrierInfo.last?.id {
                                            Divider()
                                                .padding(.vertical, 6)
                                        }
                                    }
                                }
                            }

                            SectionCard(title: "Network Info", systemImage: "network") {
                                ForEach(snapshot.networkInfo) { field in
                                    InfoFieldRow(field: field)
                                    if field.id != snapshot.networkInfo.last?.id {
                                        Divider()
                                    }
                                }
                            }

                            SectionCard(title: "Important iOS Limitations", systemImage: "exclamationmark.shield") {
                                ForEach(snapshot.notes, id: \.self) { note in
                                    Text("• \(note)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding()
                    }
                } else if viewModel.isLoading {
                    ProgressView("Loading device and network details…")
                } else {
                    ContentUnavailableView(
                        "No data yet",
                        systemImage: "antenna.radiowaves.left.and.right.slash",
                        description: Text("Tap Refresh to collect data from public iOS APIs.")
                    )
                }
            }
            .navigationTitle("Device & Network Demo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let capturedAt = viewModel.snapshot?.capturedAt {
                    HStack {
                        Text("Last updated: \(capturedAt, format: .dateTime.hour().minute().second())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                }
            }
            .onAppear {
                if viewModel.snapshot == nil {
                    viewModel.refresh()
                }
            }
        }
    }

    @ViewBuilder
    private func simSummaryView(_ summary: SimSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("SIM Detection Summary")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                AvailabilityBadge(availability: summary.availability)
            }

            Text(summary.description)
                .font(.body)
            Text("Active subscriptions detected: \(summary.activeSubscriptionsCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(summary.details)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }
}

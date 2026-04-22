import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var networkMonitor = NetworkPathMonitorService()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SectionHeaderCard(
                        title: "Demo overview",
                        summary: "This app collects all device and network information that a normal iOS app can access through public APIs.",
                        systemImage: "iphone.gen3.radiowaves.left.and.right",
                        tint: .accentColor
                    )

                    InfoItemRow(
                        item: InfoItem(
                            name: "Last refreshed",
                            value: viewModel.lastRefreshDate.formatted(date: .abbreviated, time: .standard)
                        )
                    )
                }

                Section("Device Info") {
                    SectionHeaderCard(
                        title: "Device Info",
                        summary: viewModel.deviceSnapshot.summary,
                        systemImage: "iphone",
                        tint: .blue
                    )

                    ForEach(viewModel.deviceSnapshot.items) { item in
                        InfoItemRow(item: item)
                    }

                    notesView(viewModel.deviceSnapshot.notes)
                }

                Section("SIM / Carrier Info") {
                    SectionHeaderCard(
                        title: "SIM / Carrier Info",
                        summary: viewModel.telephonySnapshot.summary,
                        systemImage: "simcard",
                        tint: .green
                    )

                    ForEach(viewModel.telephonySnapshot.items) { item in
                        InfoItemRow(item: item)
                    }

                    if viewModel.telephonySnapshot.subscriptions.isEmpty {
                        ContentUnavailableView(
                            "No active cellular services exposed",
                            systemImage: "simcard.slash",
                            description: Text("This is expected on the simulator, on Wi-Fi only devices, or when iOS does not expose carrier details.")
                        )
                        .listRowInsets(EdgeInsets())
                    } else {
                        ForEach(viewModel.telephonySnapshot.subscriptions) { subscription in
                            SubscriptionCard(subscription: subscription)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }

                    notesView(viewModel.telephonySnapshot.notes)
                }

                Section("Network Info") {
                    SectionHeaderCard(
                        title: "Network Info",
                        summary: networkMonitor.snapshot.summary,
                        systemImage: "network",
                        tint: .orange
                    )

                    ForEach(networkMonitor.snapshot.items) { item in
                        InfoItemRow(item: item)
                    }

                    notesView(networkMonitor.snapshot.notes)
                }
            }
            .navigationTitle("SIM Research Demo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        viewModel.refresh()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func notesView(_ notes: [String]) -> some View {
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)

                ForEach(Array(notes.enumerated()), id: \.offset) { entry in
                    Label {
                        Text(entry.element)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    DashboardView()
}

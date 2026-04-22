import SwiftUI

/// Displays SIM configuration, carrier details, and known limitations.
struct CarrierInfoView: View {
    @StateObject private var viewModel = CarrierInfoViewModel()

    var body: some View {
        Group {
            // SIM Configuration Section
            Section {
                ForEach(viewModel.configurationRows) { row in
                    InfoRowView(row: row)
                }
            } header: {
                Label("SIM / eSIM Configuration", systemImage: "simcard")
                    .font(.headline)
            }

            // Per-Carrier Sections
            ForEach(Array(viewModel.carrierSections.enumerated()), id: \.offset) { index, section in
                Section {
                    ForEach(section) { row in
                        InfoRowView(row: row)
                    }
                } header: {
                    Label("Carrier \(index + 1)", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.subheadline)
                }
            }

            // Limitations Section
            Section {
                ForEach(viewModel.limitationRows) { row in
                    InfoRowView(row: row)
                }
            } header: {
                Label("Inaccessible Data", systemImage: "lock.shield")
                    .font(.subheadline)
                    .foregroundColor(.red)
            } footer: {
                Text("These data points cannot be accessed via public iOS APIs due to Apple's privacy policies.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

import SwiftUI

/// Displays cellular radio, Wi-Fi, connection status, and network interface information.
struct NetworkInfoView: View {
    @StateObject private var viewModel = NetworkInfoViewModel()

    var body: some View {
        Group {
            // Cellular Radio Section
            if !viewModel.cellularRows.isEmpty {
                ForEach(Array(viewModel.cellularRows.enumerated()), id: \.offset) { index, section in
                    Section {
                        ForEach(section) { row in
                            InfoRowView(row: row)
                        }
                    } header: {
                        Label("Cellular Service \(index + 1)", systemImage: "cellularbars")
                            .font(.subheadline)
                    }
                }
            } else {
                Section {
                    Text("No active cellular services detected.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Label("Cellular", systemImage: "cellularbars")
                        .font(.headline)
                }
            }

            // Wi-Fi Section
            Section {
                ForEach(viewModel.wifiRows) { row in
                    InfoRowView(row: row)
                }
            } header: {
                Label("Wi-Fi", systemImage: "wifi")
                    .font(.headline)
            }

            // Connection Section
            Section {
                ForEach(viewModel.connectionRows) { row in
                    InfoRowView(row: row)
                }
            } header: {
                Label("Connection Details", systemImage: "network")
                    .font(.headline)
            }

            // Network Interfaces Section
            if !viewModel.interfaceRows.isEmpty {
                Section {
                    ForEach(viewModel.interfaceRows) { row in
                        InfoRowView(row: row)
                    }
                } header: {
                    Label("Network Interfaces", systemImage: "point.3.filled.connected.trianglepath.dotted")
                        .font(.headline)
                } footer: {
                    Text("Interfaces from getifaddrs(). en0 = Wi-Fi, pdp_ip = Cellular, lo0 = Loopback.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

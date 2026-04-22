import SwiftUI

/// Displays all collected device information.
struct DeviceInfoView: View {
    @StateObject private var viewModel = DeviceInfoViewModel()

    var body: some View {
        Section {
            ForEach(viewModel.rows) { row in
                InfoRowView(row: row)
            }
        } header: {
            Label("Device Info", systemImage: "iphone")
                .font(.headline)
        } footer: {
            Text("Data from UIDevice, ProcessInfo, and UIScreen APIs.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

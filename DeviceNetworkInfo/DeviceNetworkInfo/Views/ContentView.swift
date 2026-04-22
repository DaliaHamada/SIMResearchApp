import SwiftUI

/// Root view of the application.
/// Organizes all information into clearly labeled sections within a scrollable list.
struct ContentView: View {

    @State private var lastRefreshed = Date()
    @State private var refreshID = UUID()

    var body: some View {
        NavigationView {
            List {
                DeviceInfoView()
                CarrierInfoView()
                NetworkInfoView()

                Section {
                    Text("Last refreshed: \(lastRefreshed.formatted(date: .abbreviated, time: .standard))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .id(refreshID)
            .listStyle(.insetGrouped)
            .navigationTitle("Device & Network Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        refreshAll()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh all data")
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func refreshAll() {
        refreshID = UUID()
        lastRefreshed = Date()
    }
}

#Preview {
    ContentView()
}

//
//  DeviceInfoView.swift
//  SIMResearch
//

import SwiftUI

struct DeviceInfoView: View {
    @StateObject private var viewModel = DeviceInfoViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    identitySection
                    osSection
                    localeSection

                    Text("Last refreshed \(viewModel.lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Device Info")
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

    private var identitySection: some View {
        SectionCard("Identity", systemImage: "iphone", tint: .blue) {
            InfoRow(
                label: "Marketing model",
                value: viewModel.info.marketingModel,
                caption: "Mapped from utsname()",
                systemImage: "iphone"
            )
            InfoRow(
                label: "Hardware identifier",
                value: viewModel.info.hardwareIdentifier,
                caption: "uname() / utsname.machine",
                systemImage: "cpu",
                monospaced: true
            )
            InfoRow(
                label: "Generic model",
                value: viewModel.info.model,
                caption: "UIDevice.current.model",
                systemImage: "rectangle.stack"
            )
            InfoRow(
                label: "Localized model",
                value: viewModel.info.localizedModel,
                caption: "UIDevice.current.localizedModel",
                systemImage: "globe"
            )
            InfoRow(
                label: "Device name",
                value: viewModel.info.deviceName,
                caption: "UIDevice.current.name (returns generic name on iOS 16+)",
                systemImage: "person.text.rectangle"
            )
            InfoRow(
                label: "identifierForVendor",
                value: viewModel.info.identifierForVendor ?? "Unavailable",
                caption: "Vendor-scoped UUID; resets on uninstall",
                systemImage: "key.fill",
                monospaced: true
            )
        }
    }

    private var osSection: some View {
        SectionCard("Operating System", systemImage: "gearshape.2.fill", tint: .indigo) {
            InfoRow(
                label: "System name",
                value: viewModel.info.systemName,
                caption: "UIDevice.current.systemName",
                systemImage: "applelogo"
            )
            InfoRow(
                label: "System version",
                value: viewModel.info.systemVersion,
                caption: "UIDevice.current.systemVersion",
                systemImage: "number"
            )
            InfoRow(
                label: "Kernel",
                value: viewModel.info.kernelName,
                caption: "uname() sysname",
                systemImage: "terminal"
            )
        }
    }

    private var localeSection: some View {
        SectionCard("Locale & Region", systemImage: "globe", tint: .green) {
            InfoRow(
                label: "Locale",
                value: viewModel.info.localeIdentifier,
                caption: "Locale.current.identifier",
                systemImage: "character.book.closed"
            )
            InfoRow(
                label: "Region",
                value: viewModel.info.regionCode ?? "Unknown",
                caption: "Locale.current.region",
                systemImage: "flag"
            )
            InfoRow(
                label: "Time zone",
                value: viewModel.info.timeZoneIdentifier,
                caption: "TimeZone.current.identifier",
                systemImage: "clock"
            )
            InfoRow(
                label: "Preferred languages",
                value: viewModel.info.preferredLanguages.prefix(3).joined(separator: ", "),
                caption: "Locale.preferredLanguages (top 3)",
                systemImage: "text.bubble"
            )
        }
    }
}

#Preview {
    DeviceInfoView()
}

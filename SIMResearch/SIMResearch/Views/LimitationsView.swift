//
//  LimitationsView.swift
//  SIMResearch
//
//  Surfaces the iOS-specific limitations and "what is not possible"
//  guidance directly inside the app, so engineers can show the demo
//  to product / business stakeholders without having to alt-tab to
//  the README.
//

import SwiftUI

struct LimitationsView: View {

    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let symbol: String
        let kind: Kind

        enum Kind { case ok, partial, blocked }
    }

    private let items: [Item] = [
        .init(
            title: "Carrier name (CTCarrier)",
            detail: "Deprecated in iOS 16. Apple returns a placeholder ('--') and there is no replacement public API.",
            symbol: "building.2",
            kind: .partial
        ),
        .init(
            title: "MCC / MNC / ISO country code",
            detail: "Same as carrier name – returned as placeholder strings on iOS 16+.",
            symbol: "globe",
            kind: .partial
        ),
        .init(
            title: "Radio access technology (LTE, 5G, …)",
            detail: "Available via CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology and updated live.",
            symbol: "dot.radiowaves.left.and.right",
            kind: .ok
        ),
        .init(
            title: "Number of active SIMs / eSIMs",
            detail: "We can count the entries in serviceCurrentRadioAccessTechnology, but only ACTIVE plans are reported. Inactive eSIM profiles are invisible.",
            symbol: "simcard.2",
            kind: .partial
        ),
        .init(
            title: "Phone number / MSISDN",
            detail: "Not exposed by any public API. Use OTP server-side verification instead.",
            symbol: "phone.badge.checkmark",
            kind: .blocked
        ),
        .init(
            title: "ICCID / IMSI / IMEI",
            detail: "Hardware identifiers are restricted by Apple's privacy policy and require MDM / private entitlements.",
            symbol: "lock.shield",
            kind: .blocked
        ),
        .init(
            title: "SIM removal / insertion notifications",
            detail: "No public API. CoreTelephony only fires updates while the app is in the foreground and only when the active service set changes.",
            symbol: "bell.slash",
            kind: .blocked
        ),
        .init(
            title: "Which SIM received an SMS",
            detail: "Not exposed. SMS Filter Extensions can read the sender number but not the receiving SIM slot.",
            symbol: "message.badge.filled.fill",
            kind: .blocked
        ),
        .init(
            title: "Network connectivity (Wi-Fi / cellular / wired)",
            detail: "Fully supported via NWPathMonitor in the Network framework.",
            symbol: "wifi",
            kind: .ok
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("What works") {
                    ForEach(items.filter { $0.kind == .ok }) { row(for: $0) }
                }
                Section("Partially supported") {
                    ForEach(items.filter { $0.kind == .partial }) { row(for: $0) }
                }
                Section("Blocked by Apple") {
                    ForEach(items.filter { $0.kind == .blocked }) { row(for: $0) }
                }
                Section("References") {
                    Link("CoreTelephony framework",
                         destination: URL(string: "https://developer.apple.com/documentation/coretelephony")!)
                    Link("UIDevice",
                         destination: URL(string: "https://developer.apple.com/documentation/uikit/uidevice")!)
                    Link("Network framework",
                         destination: URL(string: "https://developer.apple.com/documentation/network")!)
                    Link("App privacy details on the App Store",
                         destination: URL(string: "https://developer.apple.com/app-store/app-privacy-details/")!)
                }
            }
            .navigationTitle("Limitations")
        }
    }

    private func row(for item: Item) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: badgeIcon(item.kind))
                .foregroundStyle(badgeColor(item.kind))
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Label(item.title, systemImage: item.symbol)
                    .font(.headline)
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    private func badgeIcon(_ kind: Item.Kind) -> String {
        switch kind {
        case .ok: return "checkmark.circle.fill"
        case .partial: return "exclamationmark.triangle.fill"
        case .blocked: return "xmark.octagon.fill"
        }
    }

    private func badgeColor(_ kind: Item.Kind) -> Color {
        switch kind {
        case .ok: return .green
        case .partial: return .orange
        case .blocked: return .red
        }
    }
}

#Preview {
    LimitationsView()
}

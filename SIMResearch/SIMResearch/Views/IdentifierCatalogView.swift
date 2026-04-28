//
//  IdentifierCatalogView.swift
//  SIMResearch
//
//  One screen that answers: "What's every identifier I can get from
//  this device, and exactly when does each one change?"
//
//  References (Apple docs cited inline in card sources):
//    * https://developer.apple.com/documentation/foundation/uuid
//    * https://developer.apple.com/documentation/uikit/uidevice/identifierforvendor
//

import SwiftUI

struct IdentifierCatalogView: View {

    @StateObject private var viewModel = IdentifierCatalogViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    explainerBanner
                    recommendedComposite
                    ForEach(viewModel.entries) { entry in
                        entryCard(entry)
                    }
                    triggerLegend
                    Text("Last refreshed \(viewModel.lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Identifiers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")
                }
            }
        }
    }

    // MARK: - Banner

    private var explainerBanner: some View {
        SectionCard(
            "Every identifier this app can read",
            systemImage: "list.bullet.rectangle.portrait.fill",
            tint: .blue
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Each card shows the live value, the source API, and exactly which event resets it. Sorted from most stable (rarely changes) at the top to least stable (per-call) at the bottom.")
                    .font(.subheadline)
                Text("Background reading: a UUID is a 128-bit random label (Foundation.UUID, RFC 4122 v4). Apple's intended 'one identifier per phone' is identifierForVendor — a UUID issued by iOS, scoped to your developer team and reset when the user removes every app from your team and reinstalls one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Link(destination: URL(string: "https://developer.apple.com/documentation/foundation/uuid")!) {
                        Label("Foundation.UUID", systemImage: "link")
                            .font(.caption)
                    }
                    Link(destination: URL(string: "https://developer.apple.com/documentation/uikit/uidevice/identifierforvendor")!) {
                        Label("identifierForVendor", systemImage: "link")
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - Recommended composite

    private var recommendedComposite: some View {
        SectionCard(
            "If you only want ONE 'phone id' — use this combination",
            systemImage: "checkmark.shield.fill",
            tint: .green
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("There is no single iOS API that gives you a permanent phone id, by Apple's design. The pragmatic 'closest thing' for banking / KYC is a 3-layer composite, in priority order:")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                bulletRow("1. Keychain device UUID", "survives this app being uninstalled / reinstalled — the longest-living value you can get")
                bulletRow("2. identifierForVendor (IDFV)", "second opinion; if it changes while the Keychain UUID stays the same, the user removed all your vendor's apps and came back")
                bulletRow("3. App Attest signature", "proves the request really came from this device's hardware, not a clone of the values above")
                Text("Only a factory reset (Erase All Content and Settings) or moving to a new physical iPhone resets all three at once. That's the closest iOS will let you get to 'this phone'.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func bulletRow(_ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 6))
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Per-identifier card

    @ViewBuilder
    private func entryCard(_ entry: IdentifierLifecycleEntry) -> some View {
        SectionCard(
            entry.displayName,
            systemImage: stabilitySymbol(entry.stability),
            tint: stabilityTint(entry.stability)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StatusBadge(
                        text: entry.stability.label,
                        systemImage: stabilitySymbol(entry.stability),
                        tint: stabilityTint(entry.stability)
                    )
                    Spacer()
                    if let url = entry.documentationURL {
                        Link(destination: url) {
                            Label("Docs", systemImage: "link")
                                .font(.caption)
                        }
                    }
                }

                InfoRow(
                    label: "Source",
                    value: entry.sourceAPI,
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    monospaced: true
                )

                InfoRow(
                    label: "Live value",
                    value: entry.liveValue ?? "—",
                    systemImage: "number",
                    monospaced: true
                )

                Text(entry.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("Resets when:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(IdentifierChangeTrigger.allCases) { trigger in
                    triggerRow(entry: entry, trigger: trigger)
                }
            }
        }
    }

    private func triggerRow(entry: IdentifierLifecycleEntry, trigger: IdentifierChangeTrigger) -> some View {
        let changes = entry.changes(on: trigger)
        return HStack(spacing: 8) {
            Image(systemName: changes ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(changes ? .red : .green)
                .font(.subheadline)
            Text(trigger.rawValue)
                .font(.footnote)
                .foregroundStyle(changes ? .primary : .secondary)
            Spacer()
            Text(changes ? "value changes" : "stays the same")
                .font(.caption)
                .foregroundStyle(changes ? .red : .green)
        }
    }

    // MARK: - Legend

    private var triggerLegend: some View {
        SectionCard(
            "How to read the change-trigger rows",
            systemImage: "questionmark.circle",
            tint: .gray
        ) {
            HStack(spacing: 12) {
                Label("Stays the same", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Label("Value changes", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            Text("Counter-intuitive: a green checkmark means the trigger does NOT reset the identifier (good for stability). A red X means the trigger DOES reset it.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Stability styling

    private func stabilityTint(_ s: IdentifierStability) -> Color {
        switch s {
        case .perCall:           return .red
        case .perAppInstall:     return .orange
        case .perVendorInstall:  return .yellow
        case .perSEPKey:         return .purple
        case .perDevice:         return .blue
        case .immutable:         return .green
        }
    }

    private func stabilitySymbol(_ s: IdentifierStability) -> String {
        switch s {
        case .perCall:           return "arrow.triangle.2.circlepath"
        case .perAppInstall:     return "app.badge"
        case .perVendorInstall:  return "person.text.rectangle"
        case .perSEPKey:         return "key.fill"
        case .perDevice:         return "iphone"
        case .immutable:         return "lock.fill"
        }
    }
}

#Preview {
    IdentifierCatalogView()
}

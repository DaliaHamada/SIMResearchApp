//
//  SIMInfoView.swift
//  SIMResearch
//

import SwiftUI

struct SIMInfoView: View {
    @StateObject private var viewModel = SIMInfoViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summarySection

                    if viewModel.snapshot.subscriptions.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.snapshot.subscriptions) { sub in
                            subscriptionCard(sub)
                        }
                    }

                    deprecationNotice

                    Text("Last refreshed \(viewModel.lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SIM / Carrier")
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

    private var summarySection: some View {
        SectionCard("Summary", systemImage: "simcard.2.fill", tint: .blue) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.snapshot.subscriptions.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text(viewModel.snapshot.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    StatusBadge(
                        text: viewModel.snapshot.isDualSIM ? "Dual SIM" : "Single SIM",
                        systemImage: viewModel.snapshot.isDualSIM ? "simcard.2" : "simcard",
                        tint: viewModel.snapshot.isDualSIM ? .purple : .blue
                    )
                    StatusBadge(
                        text: viewModel.snapshot.isLikelyESIMCapable ? "eSIM capable" : "eSIM unknown",
                        systemImage: "qrcode",
                        tint: viewModel.snapshot.isLikelyESIMCapable ? .green : .gray
                    )
                }
            }
            if let dataID = viewModel.snapshot.dataServiceIdentifier {
                Divider()
                InfoRow(
                    label: "Data subscription",
                    value: dataID,
                    caption: "CTTelephonyNetworkInfo.dataServiceIdentifier",
                    systemImage: "wifi.router",
                    monospaced: true
                )
            }
        }
    }

    private func subscriptionCard(_ sub: SIMSubscription) -> some View {
        SectionCard(
            "Subscription",
            systemImage: "antenna.radiowaves.left.and.right",
            tint: .purple
        ) {
            InfoRow(
                label: "Service ID",
                value: sub.id,
                caption: "Stable for the lifetime of the service",
                systemImage: "number",
                monospaced: true
            )
            InfoRow(
                label: "Carrier name",
                value: displayValue(sub.carrierName),
                caption: "CTCarrier.carrierName (deprecated iOS 16+)",
                systemImage: "building.2"
            )
            InfoRow(
                label: "Mobile Country Code (MCC)",
                value: displayValue(sub.mobileCountryCode),
                caption: "CTCarrier.mobileCountryCode",
                systemImage: "globe.europe.africa"
            )
            InfoRow(
                label: "Mobile Network Code (MNC)",
                value: displayValue(sub.mobileNetworkCode),
                caption: "CTCarrier.mobileNetworkCode",
                systemImage: "network"
            )
            InfoRow(
                label: "ISO country code",
                value: displayValue(sub.isoCountryCode),
                caption: "CTCarrier.isoCountryCode",
                systemImage: "flag"
            )
            InfoRow(
                label: "Allows VoIP",
                value: sub.allowsVOIP ? "Yes" : "No",
                caption: "CTCarrier.allowsVOIP",
                systemImage: "phone.bubble"
            )
            InfoRow(
                label: "Radio access tech",
                value: sub.radioAccessTechnologyDisplayName,
                caption: "CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology",
                systemImage: "dot.radiowaves.left.and.right"
            )
            InfoRow(
                label: "Raw RAT constant",
                value: sub.radioAccessTechnology ?? "—",
                caption: "CTRadioAccessTechnology* identifier",
                systemImage: "chevron.left.forwardslash.chevron.right",
                monospaced: true
            )
            if sub.isDeprecatedCarrierMetadata {
                Divider()
                Label(
                    "Carrier metadata is masked by iOS 16+ deprecation. The OS returns placeholders ('--') for these properties.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.footnote)
                .foregroundStyle(.orange)
            }
        }
    }

    private var emptyState: some View {
        SectionCard(
            "No active SIM",
            systemImage: "antenna.radiowaves.left.and.right.slash",
            tint: .gray
        ) {
            Text("CoreTelephony did not report any cellular subscription. " +
                 "This is expected on the iOS Simulator and on devices " +
                 "without an active plan. Insert a SIM or activate an eSIM " +
                 "and pull to refresh.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var deprecationNotice: some View {
        SectionCard(
            "Why some fields show '--'",
            systemImage: "info.circle.fill",
            tint: .orange
        ) {
            Text("Apple deprecated CTCarrier in iOS 16. Carrier name, MCC, MNC and ISO country code may be returned as a placeholder string. There is no public replacement API. The radio access technology (LTE, 5G NR, …) is still available via CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func displayValue(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "Unavailable" }
        return raw
    }
}

#Preview {
    SIMInfoView()
}

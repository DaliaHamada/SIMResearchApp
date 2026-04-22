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
            ForEach(Array(viewModel.snapshot.concreteContextFields.enumerated()), id: \.offset) { _, field in
                Divider()
                InfoRow(
                    label: field.label,
                    value: field.value,
                    caption: "CTTelephonyNetworkInfo.dataServiceIdentifier",
                    systemImage: "wifi.router",
                    monospaced: true
                )
            }
        }
    }

    private func subscriptionCard(_ sub: SIMSubscription) -> some View {
        SectionCard(
            "Subscription (non-empty values)",
            systemImage: "antenna.radiowaves.left.and.right",
            tint: .purple
        ) {
            Text("Only fields with real string values are listed. Operator name / MCC / MNC / ISO are omitted when nil, blank, or the iOS 16+ “--” mask.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(sub.concreteCollectedFields.enumerated()), id: \.offset) { _, field in
                InfoRow(
                    label: field.label,
                    value: field.value,
                    caption: captionForConcreteSIMField(field.label),
                    systemImage: systemImageForConcreteSIMField(field.label),
                    monospaced: field.label == "Service ID" || field.label == "Raw RAT constant"
                )
            }

            if sub.isDeprecatedCarrierMetadata {
                Divider()
                Label(
                    "Carrier metadata is masked by iOS 16+ deprecation. The OS returns placeholders ('--') for CTCarrier-backed properties; there is no public replacement.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.footnote)
                .foregroundStyle(.orange)
            }
        }
    }

    private func captionForConcreteSIMField(_ label: String) -> String {
        switch label {
        case "Service ID":
            return "CTTelephonyNetworkInfo service key; stable for the lifetime of the subscription"
        case "Allows VoIP":
            return "CTCarrier.allowsVOIP"
        case "Radio access technology":
            return "Mapped from serviceCurrentRadioAccessTechnology"
        case "Raw RAT constant":
            return "CTRadioAccessTechnology* constant"
        case "Carrier name":
            return "CTCarrier.carrierName"
        case "MCC":
            return "CTCarrier.mobileCountryCode"
        case "MNC":
            return "CTCarrier.mobileNetworkCode"
        case "ISO country code":
            return "CTCarrier.isoCountryCode"
        default:
            return "CoreTelephony"
        }
    }

    private func systemImageForConcreteSIMField(_ label: String) -> String {
        switch label {
        case "Service ID": return "number"
        case "Allows VoIP": return "phone.bubble"
        case "Radio access technology": return "dot.radiowaves.left.and.right"
        case "Raw RAT constant": return "chevron.left.forwardslash.chevron.right"
        case "Carrier name": return "building.2"
        case "MCC": return "globe.europe.africa"
        case "MNC": return "network"
        case "ISO country code": return "flag"
        default: return "doc.text"
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

}

#Preview {
    SIMInfoView()
}

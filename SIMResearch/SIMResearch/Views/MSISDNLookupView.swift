//
//  MSISDNLookupView.swift
//  SIMResearch
//
//  Tab that lets the user run the four Egyptian carrier USSD codes
//  to retrieve their own phone number (MSISDN). The screen makes the
//  iOS limitations explicit at the top — there is no silent / background
//  dialing API, and the carrier's USSD response is not exposed to the
//  app — and then provides the only flow that actually works:
//
//    1. App pre-fills the dialer with the carrier's USSD code.
//    2. User confirms the call on the system sheet.
//    3. User reads the number from the carrier's response.
//    4. User pastes / types it back into the app.
//

import SwiftUI

struct MSISDNLookupView: View {

    @StateObject private var viewModel = MSISDNLookupViewModel()
    @State private var inputs: [EgyptianCarrier: String] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    iosLimitsBanner
                    ForEach(EgyptianCarrier.allCases) { carrier in
                        carrierCard(carrier)
                    }
                    if !viewModel.entries.isEmpty {
                        capturedHistory
                    }
                    referenceSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("MSISDN via USSD")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        viewModel.clearAll()
                        inputs.removeAll()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear captured numbers")
                    .disabled(viewModel.entries.isEmpty)
                }
            }
        }
    }

    // MARK: - Banner

    private var iosLimitsBanner: some View {
        SectionCard(
            "iOS limits — read me first",
            systemImage: "exclamationmark.shield.fill",
            tint: .orange
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("There is no public API to dial USSD codes silently or in the background, and iOS does not expose the carrier's USSD response to apps.")
                    .font(.subheadline)
                Text("The flow below is user-assisted: the app pre-fills the dialer, you confirm the call on the system sheet, then read the number from the carrier reply and type it back here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Carrier card

    @ViewBuilder
    private func carrierCard(_ carrier: EgyptianCarrier) -> some View {
        let phase = viewModel.phase(for: carrier)
        let latest = viewModel.latestEntry(for: carrier)
        let inputBinding = Binding<String>(
            get: { inputs[carrier] ?? "" },
            set: { inputs[carrier] = $0 }
        )

        SectionCard(carrier.displayName, systemImage: carrier.symbol, tint: tint(for: carrier)) {
            VStack(alignment: .leading, spacing: 12) {
                ussdRow(carrier)

                HStack(spacing: 8) {
                    dialButton(carrier)
                    Button {
                        viewModel.copyCode(for: carrier)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }

                phaseBanner(carrier, phase: phase)

                if let latest {
                    capturedRow(latest)
                }

                Divider()

                Text("Number from the carrier reply")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("e.g. 010 1234 5678", text: inputBinding)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                HStack {
                    Button {
                        let raw = inputs[carrier] ?? ""
                        if viewModel.saveMSISDN(raw, for: carrier) {
                            inputs[carrier] = ""
                        }
                    } label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled((inputs[carrier] ?? "").trimmingCharacters(in: .whitespaces).isEmpty)

                    Spacer()

                    if phase == .invalidInput {
                        Label("Not a valid Egyptian mobile number", systemImage: "xmark.octagon.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func ussdRow(_ carrier: EgyptianCarrier) -> some View {
        HStack {
            Image(systemName: "number")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("USSD code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(carrier.ussdCode)
                    .font(.title3.monospaced().weight(.semibold))
                    .textSelection(.enabled)
            }
            Spacer()
            if !carrier.mobileNetworkCodes.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("MNC")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(carrier.mobileNetworkCodes.joined(separator: ", "))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func dialButton(_ carrier: EgyptianCarrier) -> some View {
        Button {
            viewModel.dial(carrier)
        } label: {
            Label(carrier.requiresManualDial ? "Open dialer (manual)" : "Open dialer",
                  systemImage: "phone.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(tint(for: carrier))
    }

    @ViewBuilder
    private func phaseBanner(_ carrier: EgyptianCarrier, phase: CarrierLookupPhase) -> some View {
        switch phase {
        case .idle:
            EmptyView()
        case .dialing:
            Label("Asking iOS to open the dialer…", systemImage: "ellipsis.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .awaitingUserInput:
            Label("Confirm the call, read the number from the carrier response, then enter it below.",
                  systemImage: "person.crop.circle.badge.checkmark")
                .font(.caption)
                .foregroundStyle(.blue)
                .fixedSize(horizontal: false, vertical: true)
        case .manualDialRequired:
            Label("iOS won't open USSD codes that start with '#'. The code was copied to your clipboard — paste it into the Phone app and dial manually.",
                  systemImage: "hand.tap.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        case .dialFailed:
            Label("The dialer URL could not be built. This is a programming error, not an iOS one — please file a bug.",
                  systemImage: "xmark.octagon.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        case .invalidInput:
            EmptyView()
        }
    }

    private func capturedRow(_ entry: MSISDNEntry) -> some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Last captured")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.msisdn)
                    .font(.subheadline.monospaced().weight(.semibold))
                    .textSelection(.enabled)
            }
            Spacer()
            Text(entry.capturedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.green.opacity(0.08))
        )
    }

    // MARK: - History

    private var capturedHistory: some View {
        SectionCard(
            "All captured numbers",
            systemImage: "list.bullet.rectangle.portrait",
            tint: .indigo
        ) {
            ForEach(viewModel.entries) { entry in
                HStack {
                    Image(systemName: entry.carrier.symbol)
                        .foregroundStyle(tint(for: entry.carrier))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.carrier.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text(entry.msisdn)
                            .font(.subheadline.monospaced())
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Text(entry.capturedAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
                if entry.id != viewModel.entries.last?.id {
                    Divider()
                }
            }
        }
    }

    // MARK: - Reference

    private var referenceSection: some View {
        SectionCard(
            "USSD code reference",
            systemImage: "list.number",
            tint: .gray
        ) {
            ForEach(viewModel.ussdCodeReference, id: \.carrier) { row in
                HStack {
                    Text(row.carrier.displayName)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(row.code)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Helpers

    private func tint(for carrier: EgyptianCarrier) -> Color {
        switch carrier {
        case .vodafone: return .red
        case .etisalat: return .green
        case .orange:   return .orange
        case .we:       return .purple
        }
    }
}

#Preview {
    MSISDNLookupView()
}

//
//  DeviceTrustView.swift
//  SIMResearch
//
//  The "this is what replaced IMEI on iOS" tab. Built for the
//  conversation with non-iOS stakeholders (regulators, PMs, banking
//  ops) who arrive expecting an IMEI field — it shows the four
//  layers iOS actually exposes, live values from this device, and a
//  one-tap demo that proves the App Attest signature works.
//

import SwiftUI

struct DeviceTrustView: View {

    @StateObject private var viewModel = DeviceTrustViewModel()
    @State private var demoPayload: String = "GET /v1/transfers HTTP/1.0\nnonce: 0xCAFEBABE"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    explainerBanner
                    idfvCard
                    keychainCard
                    deviceCheckCard
                    appAttestCard
                    if !viewModel.snapshot.concreteRows.isEmpty {
                        rawSnapshotCard
                    }
                    resetCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Device Trust")
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
            .overlay {
                if viewModel.isWorking {
                    ProgressView().controlSize(.large)
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Banner

    private var explainerBanner: some View {
        SectionCard(
            "What replaced IMEI on iOS",
            systemImage: "checkmark.shield.fill",
            tint: .green
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Apple does not let App Store apps read IMEI / IMSI / ICCID / EID / MEID. The four layers below are the App Store-safe replacements every licensed banking and government app uses for device identity, fraud detection, and request integrity.")
                    .font(.subheadline)
                Text("Each layer is technically stronger than IMEI for its real use case — IMEI is a static, spoofable string; the layers below combine persistence, server-verified uniqueness, and per-request hardware signatures from the Secure Enclave.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - IDFV

    private var idfvCard: some View {
        SectionCard("1. identifierForVendor (IDFV)", systemImage: "person.text.rectangle", tint: .blue) {
            InfoRow(
                label: "Value",
                value: viewModel.snapshot.identifierForVendor ?? "—",
                caption: "UIDevice.identifierForVendor — UUID per (vendor, device); resets when all vendor apps are uninstalled.",
                systemImage: "number",
                monospaced: true
            )
        }
    }

    // MARK: - Keychain UUID

    private var keychainCard: some View {
        SectionCard("2. Keychain device UUID", systemImage: "key.fill", tint: .indigo) {
            InfoRow(
                label: "Value",
                value: viewModel.snapshot.keychainDeviceUUID ?? "—",
                caption: "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly — survives app uninstall on the SAME device; never syncs to iCloud.",
                systemImage: "lock.shield",
                monospaced: true
            )
            Text("Bank use case: persistent half of 'remember this device' KYC binding. Pair with IDFV to detect fresh installs vs. fresh devices.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - DeviceCheck

    private var deviceCheckCard: some View {
        SectionCard("3. DeviceCheck", systemImage: "checkmark.seal.fill", tint: .orange) {
            switch viewModel.snapshot.deviceCheck {
            case .unsupported:
                Label("Not supported on this device (Simulator or unsupported model).",
                      systemImage: "xmark.octagon.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            case .ready:
                VStack(alignment: .leading, spacing: 8) {
                    Text("DCDevice is ready. Tap below to generate a token; in production the token is POSTed to your backend, which exchanges it with Apple to read/write 2 device-scoped bits per developer team.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        viewModel.generateDeviceCheckToken()
                    } label: {
                        Label("Generate token", systemImage: "key.horizontal.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .tokenGenerated(let token, let at):
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        label: "Token",
                        value: previewTruncated(token, max: 80),
                        caption: "Base64. Send the FULL value to your backend, never log it.",
                        systemImage: "doc.text",
                        monospaced: true
                    )
                    InfoRow(
                        label: "Generated",
                        value: at.formatted(date: .omitted, time: .standard),
                        systemImage: "clock"
                    )
                    Button {
                        viewModel.generateDeviceCheckToken()
                    } label: {
                        Label("Generate again", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            case .failed(let message):
                Label(message, systemImage: "xmark.octagon.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - App Attest

    private var appAttestCard: some View {
        SectionCard("4. App Attest", systemImage: "lock.shield.fill", tint: .purple) {
            switch viewModel.snapshot.appAttest {
            case .unsupported:
                Label("Not supported (Simulator, jailbroken device, or unsupported model). The Secure Enclave is required.",
                      systemImage: "xmark.octagon.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)

            case .noKey:
                VStack(alignment: .leading, spacing: 8) {
                    Text("No Secure Enclave key yet. Tap to generate one. The private key never leaves the SEP; only the opaque key id is persisted in Keychain.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        viewModel.generateAppAttestKey()
                    } label: {
                        Label("Generate key", systemImage: "key.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .keyGenerated(let keyId):
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        label: "Key id",
                        value: previewTruncated(keyId, max: 80),
                        caption: "Persisted in Keychain. The Secure Enclave private key is addressed by this id.",
                        systemImage: "key",
                        monospaced: true
                    )
                    Text("Next: attest the key. Production code MUST fetch a single-use challenge from your backend; the demo generates one locally so you can see the flow on-device.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        viewModel.attestExistingKey()
                    } label: {
                        Label("Attest with demo challenge", systemImage: "checkmark.seal")
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .attested(let keyId, let size, let at):
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        label: "Key id",
                        value: previewTruncated(keyId, max: 80),
                        systemImage: "key",
                        monospaced: true
                    )
                    InfoRow(label: "Attestation size", value: "\(size) bytes", systemImage: "doc.zipper")
                    InfoRow(label: "Attested at", value: at.formatted(date: .omitted, time: .standard), systemImage: "clock")
                    Divider()
                    Text("Per-request signature (assertion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $demoPayload)
                        .font(.footnote.monospaced())
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                    Button {
                        viewModel.signDemoPayload(demoPayload)
                    } label: {
                        Label("Sign payload with attested key", systemImage: "signature")
                    }
                    .buttonStyle(.borderedProminent)

                    if let assertion = viewModel.lastAssertion {
                        InfoRow(
                            label: "Assertion",
                            value: previewTruncated(assertion.base64EncodedString(), max: 80),
                            caption: "Base64. Ship to backend with the request; backend verifies with the public key it stored at attestation time.",
                            systemImage: "checkmark.shield",
                            monospaced: true
                        )
                        InfoRow(
                            label: "Assertion size",
                            value: "\(assertion.count) bytes",
                            systemImage: "doc.zipper"
                        )
                    }
                    if let err = viewModel.lastError {
                        Label(err, systemImage: "xmark.octagon.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

            case .failed(let message):
                Label(message, systemImage: "xmark.octagon.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Raw rows

    private var rawSnapshotCard: some View {
        SectionCard("Raw snapshot", systemImage: "list.bullet.rectangle", tint: .gray) {
            ForEach(Array(viewModel.snapshot.concreteRows.enumerated()), id: \.offset) { _, row in
                InfoRow(
                    label: row.label,
                    value: row.value,
                    monospaced: true
                )
            }
            Text("Captured at \(viewModel.snapshot.capturedAt, style: .time)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    // MARK: - Reset

    private var resetCard: some View {
        SectionCard("Local reset", systemImage: "arrow.counterclockwise", tint: .red) {
            Text("Wipes the Keychain UUID and the App Attest key id from this app's slot. The Secure Enclave key itself stays parked until the device is wiped — that's by design and is what makes attestation forgery-proof.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive) {
                viewModel.resetLocalIdentity()
            } label: {
                Label("Reset local identity", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private func previewTruncated(_ value: String, max: Int) -> String {
        guard value.count > max else { return value }
        let head = value.prefix(max / 2)
        let tail = value.suffix(max / 2 - 1)
        return "\(head)…\(tail)"
    }
}

#Preview {
    DeviceTrustView()
}

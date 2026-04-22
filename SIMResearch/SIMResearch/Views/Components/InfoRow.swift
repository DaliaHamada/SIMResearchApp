//
//  InfoRow.swift
//  SIMResearch
//
//  Generic key/value row, with an optional caption explaining the
//  source of the value (e.g. "via UIDevice.identifierForVendor").
//

import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    var caption: String? = nil
    var systemImage: String? = nil
    var monospaced: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
                    .frame(width: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let caption {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 12)
            Text(value.isEmpty ? "—" : value)
                .font(monospaced ? .subheadline.monospaced() : .subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}

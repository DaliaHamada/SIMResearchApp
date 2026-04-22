//
//  DataFieldListSection.swift
//  Reusable section: title + list of data fields with footnotes.
//

import SwiftUI

struct DataFieldListSection: View {
    let title: String
    let systemImage: String
    let fields: [DataField]
    var footer: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(fields) { field in
                    DataFieldRow(field: field)
                    if field.id != fields.last?.id {
                        Divider()
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )

            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DataFieldRow: View {
    let field: DataField

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(field.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(field.value)
                        .font(.body)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 8)
                Text(field.availability.displayName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.trailing)
            }

            Text("API: `\(field.api)`")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if let note = field.note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    DataFieldListSection(
        title: "Sample",
        systemImage: "info.circle",
        fields: [
            DataField(
                label: "Example",
                value: "Value",
                api: "Test.api",
                availability: .generallyAvailable
            )
        ]
    )
    .padding()
}

import SwiftUI

struct InfoFieldRow: View {
    let field: InfoField

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(field.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                AvailabilityBadge(availability: field.availability)
            }

            Text(field.value)
                .font(.body)
                .foregroundStyle(.primary)

            Text("API: \(field.apiName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let note = field.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

import SwiftUI

struct SectionHeaderCard: View {
    let title: String
    let summary: String
    let systemImage: String
    let tint: Color

    init(
        title: String,
        summary: String,
        systemImage: String = "info.circle",
        tint: Color = .blue
    ) {
        self.title = title
        self.summary = summary
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}

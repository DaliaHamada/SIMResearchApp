import SwiftUI

/// Reusable view component that displays a single key-value info row
/// with an optional detail disclosure.
struct InfoRowView: View {
    let row: InfoRow

    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(row.label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 120, alignment: .leading)

                Spacer()

                Text(row.value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
                    .textSelection(.enabled)

                if row.detail != nil {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if row.detail != nil {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDetail.toggle()
                    }
                }
            }

            if showDetail, let detail = row.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 2)
    }
}

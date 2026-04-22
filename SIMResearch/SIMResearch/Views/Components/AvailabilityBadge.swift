import SwiftUI

struct AvailabilityBadge: View {
    let availability: DataAvailability
    
    private var color: Color {
        switch availability {
        case .available:
            return .green
        case .limited:
            return .orange
        case .unavailable:
            return .red
        }
    }

    var body: some View {
        Text(availability.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
            )
    }
}

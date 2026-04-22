import SwiftUI

struct SubscriptionCard: View {
    let subscription: CarrierSubscriptionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.carrierName)
                        .font(.headline)
                    Text(subscription.serviceIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if subscription.isCurrentDataService {
                    Label("Data service", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Divider()

            VStack(spacing: 10) {
                InfoItemRow(item: InfoItem(name: "Carrier name", value: subscription.carrierName))
                InfoItemRow(item: InfoItem(name: "MCC", value: subscription.mobileCountryCode))
                InfoItemRow(item: InfoItem(name: "MNC", value: subscription.mobileNetworkCode))
                InfoItemRow(item: InfoItem(name: "ISO country code", value: subscription.isoCountryCode))
                InfoItemRow(item: InfoItem(name: "Radio access technology", value: subscription.radioAccessTechnology))
                InfoItemRow(item: InfoItem(name: "Allows VoIP", value: subscription.allowsVoIP))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

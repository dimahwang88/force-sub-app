import SwiftUI

struct BookingRowView: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 12) {
            // Date/time column
            VStack(spacing: 2) {
                Text(booking.classDateTime.dayAbbreviation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(booking.classDateTime.dayNumber)
                    .font(.title3.bold())
                Text(booking.classDateTime.formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)

            Divider()
                .frame(height: 40)

            // Booking info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(booking.className)
                        .font(.body.bold())
                    ClassLevelBadge(level: booking.classLevel)
                }
                Text(booking.instructor)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(booking.location, systemImage: "mappin.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

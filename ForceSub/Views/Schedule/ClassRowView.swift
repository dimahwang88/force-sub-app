import SwiftUI

struct ClassRowView: View {
    let gymClass: GymClass

    var body: some View {
        HStack(spacing: 12) {
            // Time column
            VStack(alignment: .center, spacing: 2) {
                Text(gymClass.dateTime.formattedTime)
                    .font(.subheadline.bold())
                Text("\(gymClass.durationMinutes) min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70)

            Divider()
                .frame(height: 40)

            // Class info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(gymClass.name)
                        .font(.body.bold())
                    ClassLevelBadge(level: gymClass.level)
                }

                Text(gymClass.instructor)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Label(gymClass.location, systemImage: "mappin.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    SpotCountView(
                        available: gymClass.availableSpots,
                        total: gymClass.totalSpots
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

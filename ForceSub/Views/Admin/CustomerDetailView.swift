import SwiftUI

struct CustomerDetailView: View {
    let customer: AppUser
    let bookings: [Booking]

    private var upcomingBookings: [Booking] {
        bookings.filter { $0.classDateTime >= Date() }
            .sorted { $0.classDateTime < $1.classDateTime }
    }

    private var pastBookings: [Booking] {
        bookings.filter { $0.classDateTime < Date() }
            .sorted { $0.classDateTime > $1.classDateTime }
    }

    var body: some View {
        List {
            // Profile header
            Section {
                VStack(spacing: 12) {
                    if let urlString = customer.selfieURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.secondary)
                    }

                    Text(customer.displayName)
                        .font(.title2.bold())

                    if let belt = customer.beltRank, !belt.isEmpty {
                        Text(belt.capitalized)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.beltColor(for: belt).opacity(0.2))
                            .foregroundStyle(Color.beltColor(for: belt))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Contact info
            Section("Contact") {
                LabeledContent("Email", value: customer.email)
                if let phone = customer.phone, !phone.isEmpty {
                    LabeledContent("Phone", value: phone)
                }
                LabeledContent("Joined", value: customer.createdAt.formattedShort)
            }

            // Stats
            Section("Stats") {
                LabeledContent("Classes Attended", value: "\(pastBookings.count)")
                LabeledContent("Upcoming Bookings", value: "\(upcomingBookings.count)")
                if let last = pastBookings.first?.classDateTime {
                    LabeledContent("Last Attended", value: last.formattedShort)
                }
            }

            // Upcoming bookings
            if !upcomingBookings.isEmpty {
                Section("Upcoming Bookings") {
                    ForEach(upcomingBookings) { booking in
                        BookingInfoRow(booking: booking)
                    }
                }
            }

            // Past bookings
            if !pastBookings.isEmpty {
                Section("Past Classes") {
                    ForEach(pastBookings.prefix(20)) { booking in
                        BookingInfoRow(booking: booking)
                    }
                    if pastBookings.count > 20 {
                        Text("+ \(pastBookings.count - 20) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(customer.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Booking Info Row

private struct BookingInfoRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(booking.className)
                .font(.subheadline.bold())
            HStack {
                Label(booking.classDateTime.formattedDateTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(booking.instructor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

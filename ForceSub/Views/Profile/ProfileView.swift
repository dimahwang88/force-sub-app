import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading profile...")
            } else {
                profileContent
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .task {
            if let userId = authViewModel.currentUserId {
                await viewModel.loadProfile(userId: userId)
            }
        }
    }

    private var profileContent: some View {
        List {
            // User info + belt section
            Section {
                if let user = viewModel.user {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(.title3.bold())
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    // Belt rank
                    if let beltRank = user.beltRank, !beltRank.isEmpty {
                        HStack {
                            Label {
                                Text("Belt Rank")
                            } icon: {
                                Image(systemName: "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.beltColor(for: beltRank))
                            }
                            Spacer()
                            Text(beltRank.capitalized)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.beltColor(for: beltRank))
                        }
                    }
                }
            }

            // Attendance stats section
            Section("Attendance") {
                HStack {
                    Label("Classes Attended", systemImage: "checkmark.circle.fill")
                    Spacer()
                    Text("\(viewModel.attendedCount)")
                        .font(.title3.bold())
                        .foregroundStyle(.appPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity")
                        .font(.subheadline.bold())
                    AttendanceHeatmapView(attendanceDays: viewModel.attendanceDays)
                }
                .padding(.vertical, 4)
            }

            // Upcoming bookings section
            Section {
                if viewModel.upcomingBookings.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No upcoming bookings")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.upcomingBookings) { booking in
                        BookingRowView(booking: booking)
                    }
                }
            } header: {
                HStack {
                    Text("Upcoming Bookings")
                    Spacer()
                    Text("\(viewModel.upcomingBookings.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Account section
            Section {
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            }
        }
    }
}

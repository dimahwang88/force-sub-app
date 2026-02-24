import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var showSelfieCaptureSheet = false

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
        .sheet(isPresented: $showSelfieCaptureSheet) {
            SelfieCaptureView()
        }
        .onChange(of: showSelfieCaptureSheet) { _, isPresented in
            if !isPresented, let userId = authViewModel.currentUserId {
                Task { await viewModel.loadProfile(userId: userId) }
            }
        }
    }

    private var profileContent: some View {
        List {
            // User info + belt section
            Section {
                if let user = viewModel.user {
                    HStack(spacing: 16) {
                        selfieAvatar(url: user.selfieURL)
                            .onTapGesture { showSelfieCaptureSheet = true }
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
                        .foregroundStyle(Color.appPrimary)
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

            // Selfie / Face Recognition section
            Section("Face Recognition") {
                HStack {
                    Label {
                        Text(viewModel.user?.selfieURL != nil ? "Selfie on file" : "No selfie on file")
                    } icon: {
                        Image(systemName: viewModel.user?.selfieURL != nil
                              ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundStyle(viewModel.user?.selfieURL != nil ? .green : .orange)
                    }
                    Spacer()
                    Button(viewModel.user?.selfieURL != nil ? "Update" : "Add") {
                        showSelfieCaptureSheet = true
                    }
                    .font(.subheadline)
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

    @ViewBuilder
    private func selfieAvatar(url: String?) -> some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    defaultAvatar
                case .empty:
                    ProgressView()
                        .frame(width: 50, height: 50)
                @unknown default:
                    defaultAvatar
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 50))
            .foregroundStyle(.secondary)
    }
}

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var showSelfieCaptureSheet = false
    @State private var noAdminExists = false
    @State private var adminCode = ""
    @State private var showAdminCodeField = false

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
            noAdminExists = !(await authViewModel.checkAdminExists())
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
                            HStack(spacing: 6) {
                                Text(user.displayName)
                                    .font(.title3.bold())
                                Image(systemName: user.admin ? "shield.checkered" : "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(user.admin ? .blue : .secondary)
                            }
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(user.admin ? "Admin" : "Customer")
                                .font(.caption)
                                .foregroundStyle(user.admin ? .blue : .secondary)
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

            // Admin section — only shown for non-admin users
            if authViewModel.currentUser?.admin != true {
                Section {
                    if noAdminExists {
                        Button {
                            Task {
                                await authViewModel.becomeAdmin()
                                noAdminExists = false
                            }
                        } label: {
                            Label("Become Admin", systemImage: "shield.checkered")
                        }
                    }

                    if showAdminCodeField {
                        TextField("Admin Invite Code", text: $adminCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        Button {
                            Task {
                                await authViewModel.redeemAdminCode(adminCode)
                                adminCode = ""
                                showAdminCodeField = false
                            }
                        } label: {
                            Label("Submit Code", systemImage: "checkmark.circle.fill")
                        }
                        .disabled(adminCode.isEmpty)
                    } else {
                        Button {
                            showAdminCodeField = true
                        } label: {
                            Label("I have an admin invite code", systemImage: "shield.checkered")
                        }
                    }
                } footer: {
                    if noAdminExists {
                        Text("No admin account exists yet. Tap to make this the admin account.")
                    } else {
                        Text("Enter an invite code from an admin to get admin access.")
                    }
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

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        List {
            // User info section
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
                } else if viewModel.isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading profile...")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Belt rank (if set)
            if let beltRank = viewModel.user?.beltRank {
                Section("Training") {
                    HStack {
                        Text("Belt Rank")
                        Spacer()
                        Text(beltRank.capitalized)
                            .foregroundStyle(.secondary)
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
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .task {
            if let userId = authViewModel.currentUserId {
                await viewModel.loadProfile(userId: userId)
            }
        }
    }
}

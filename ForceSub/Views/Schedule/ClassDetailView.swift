import SwiftUI

struct ClassDetailView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel: ClassDetailViewModel
    @State private var showCancelConfirmation = false
    @State private var showEditClass = false

    private var isAdmin: Bool {
        authViewModel.currentUser?.admin ?? false
    }

    init(gymClass: GymClass) {
        _viewModel = State(initialValue: ClassDetailViewModel(gymClass: gymClass))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                Divider()
                details
                Divider()
                description
                Spacer(minLength: 24)
                bookingButton
            }
            .padding()
        }
        .navigationTitle(viewModel.gymClass.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if isAdmin {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEditClass = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditClass) {
            NavigationStack {
                EditClassView(gymClass: viewModel.gymClass)
            }
        }
        .onChange(of: showEditClass) { _, isPresented in
            if !isPresented {
                Task { await viewModel.refreshClass() }
            }
        }
        .task {
            if let userId = authViewModel.currentUserId {
                await viewModel.checkExistingBooking(userId: userId)
            }
        }
        .alert("Cancel Booking", isPresented: $showCancelConfirmation) {
            Button("Cancel Booking", role: .destructive) {
                Task { await viewModel.cancelBooking() }
            }
            Button("Keep Booking", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel your booking for this class?")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ClassLevelBadge(level: viewModel.gymClass.level)
                Spacer()
                SpotCountView(
                    available: viewModel.gymClass.availableSpots,
                    total: viewModel.gymClass.totalSpots
                )
            }
            Text(viewModel.gymClass.instructor)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Details Grid

    private var details: some View {
        VStack(spacing: 12) {
            DetailRow(icon: "calendar", label: "Date", value: viewModel.gymClass.dateTime.formattedShort)
            DetailRow(icon: "clock", label: "Time", value: "\(viewModel.gymClass.dateTime.formattedTime) - \(viewModel.gymClass.endTime.formattedTime)")
            DetailRow(icon: "timer", label: "Duration", value: "\(viewModel.gymClass.durationMinutes) minutes")
            DetailRow(icon: "mappin.circle", label: "Location", value: viewModel.gymClass.location)
        }
    }

    // MARK: - Description

    private var description: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Class")
                .font(.headline)
            Text(viewModel.gymClass.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Booking Button

    private var bookingButton: some View {
        VStack(spacing: 8) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if viewModel.isBooked {
                Button(role: .destructive) {
                    showCancelConfirmation = true
                } label: {
                    Label("Cancel Booking", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isLoading)
            } else {
                Button {
                    guard let userId = authViewModel.currentUserId else { return }
                    Task { await viewModel.bookClass(userId: userId) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label(
                            viewModel.gymClass.isFull ? "Class Full" : "Book Class",
                            systemImage: viewModel.gymClass.isFull ? "xmark.circle" : "checkmark.circle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.gymClass.isFull || viewModel.isLoading)
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.subheadline)
            Spacer()
        }
    }
}

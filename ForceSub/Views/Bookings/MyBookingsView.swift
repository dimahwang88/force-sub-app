import SwiftUI

struct MyBookingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = MyBookingsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading bookings...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.upcomingBookings.isEmpty && viewModel.pastBookings.isEmpty {
                ContentUnavailableView(
                    "No Bookings",
                    systemImage: "list.clipboard",
                    description: Text("You haven't booked any classes yet. Head to the Schedule tab to find a class.")
                )
            } else {
                bookingsList
            }
        }
        .navigationTitle("My Bookings")
        .task {
            if let userId = authViewModel.currentUserId {
                await viewModel.loadBookings(userId: userId)
            }
        }
        .refreshable {
            if let userId = authViewModel.currentUserId {
                await viewModel.loadBookings(userId: userId)
            }
        }
    }

    private var bookingsList: some View {
        List {
            if !viewModel.upcomingBookings.isEmpty {
                Section("Upcoming") {
                    ForEach(viewModel.upcomingBookings) { booking in
                        BookingRowView(booking: booking)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Cancel", role: .destructive) {
                                    if let userId = authViewModel.currentUserId {
                                        Task {
                                            await viewModel.cancelBooking(booking, userId: userId)
                                        }
                                    }
                                }
                            }
                    }
                }
            }

            if !viewModel.pastBookings.isEmpty {
                Section("Past") {
                    ForEach(viewModel.pastBookings) { booking in
                        BookingRowView(booking: booking)
                            .opacity(0.6)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

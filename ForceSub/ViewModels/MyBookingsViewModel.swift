import Foundation
import Observation

@Observable
final class MyBookingsViewModel {
    var upcomingBookings: [Booking] = []
    var pastBookings: [Booking] = []
    var isLoading = false
    var errorMessage: String?

    private let bookingService = BookingService()

    func loadBookings(userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let all = try await bookingService.fetchBookings(userId: userId)
            let now = Date()
            upcomingBookings = all.filter { $0.classDateTime >= now }
            pastBookings = all.filter { $0.classDateTime < now }
        } catch {
            errorMessage = "Failed to load bookings."
        }
        isLoading = false
    }

    func cancelBooking(_ booking: Booking, userId: String) async {
        do {
            try await bookingService.cancelBooking(booking)
            await loadBookings(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

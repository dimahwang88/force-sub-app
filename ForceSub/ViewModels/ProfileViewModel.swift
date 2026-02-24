import Foundation
import Observation
import FirebaseFirestore

@Observable
final class ProfileViewModel {
    var user: AppUser?
    var isLoading = false
    var errorMessage: String?

    var upcomingBookings: [Booking] = []
    var attendedCount: Int = 0
    /// Maps calendar day (start of day) to number of classes attended
    var attendanceDays: [Date: Int] = [:]

    private let db = Firestore.firestore()
    private let bookingService = BookingService()

    func loadProfile(userId: String) async {
        isLoading = true
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            user = try? doc.data(as: AppUser.self)
        } catch {
            errorMessage = "Failed to load profile."
        }

        do {
            let allBookings = try await bookingService.fetchBookings(userId: userId)
            let now = Date()
            let calendar = Calendar.current

            upcomingBookings = allBookings.filter { $0.classDateTime >= now }

            let pastBookings = allBookings.filter { $0.classDateTime < now }
            attendedCount = pastBookings.count

            var days: [Date: Int] = [:]
            for booking in pastBookings {
                let day = calendar.startOfDay(for: booking.classDateTime)
                days[day, default: 0] += 1
            }
            attendanceDays = days
        } catch {
            // Booking fetch failure is non-critical
        }

        isLoading = false
    }
}

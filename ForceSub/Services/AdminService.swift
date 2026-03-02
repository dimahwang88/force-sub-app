import Foundation
import FirebaseFirestore

final class AdminService {
    private let db = Firestore.firestore()

    /// Fetch all customer users (non-admin accounts).
    func fetchAllCustomers() async throws -> [AppUser] {
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: AppUser.self) }
            .filter { $0.resolvedAccountType == .customer }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// Fetch all confirmed bookings across all users.
    func fetchAllBookings() async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("status", isEqualTo: BookingStatus.confirmed.rawValue)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Booking.self) }
            .sorted { $0.classDateTime < $1.classDateTime }
    }

    /// Fetch bookings for a specific user.
    func fetchBookings(for userId: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: BookingStatus.confirmed.rawValue)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Booking.self) }
            .sorted { $0.classDateTime < $1.classDateTime }
    }
}

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

    // MARK: - Admin Invite Codes

    /// Generate a new admin invite code. The document ID is the code itself.
    func generateAdminCode(createdBy: String) async throws -> String {
        let code = generateRandomCode()
        let adminCode = AdminCode(createdBy: createdBy, createdAt: Date())
        try db.collection("adminCodes").document(code).setData(from: adminCode)
        return code
    }

    /// Fetch all admin invite codes.
    func fetchAdminCodes() async throws -> [AdminCode] {
        let snapshot = try await db.collection("adminCodes")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AdminCode.self) }
    }

    /// Delete an unused admin invite code.
    func deleteAdminCode(_ code: String) async throws {
        try await db.collection("adminCodes").document(code).delete()
    }

    private func generateRandomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no ambiguous chars (0/O, 1/I)
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}

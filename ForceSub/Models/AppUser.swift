import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    var displayName: String
    let createdAt: Date
    var beltRank: String?
    var phone: String?
    var isAdmin: Bool?
    /// Download URL for the user's selfie stored in Firebase Storage
    var selfieURL: String?

    var admin: Bool {
        isAdmin ?? false
    }
}

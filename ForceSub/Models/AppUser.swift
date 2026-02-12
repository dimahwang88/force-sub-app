import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    var displayName: String
    let createdAt: Date
    var beltRank: String?
    var phone: String?
}

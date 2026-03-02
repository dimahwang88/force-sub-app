import Foundation
import FirebaseFirestore

struct AdminCode: Codable, Identifiable {
    @DocumentID var id: String?
    let createdBy: String
    let createdAt: Date
    var usedBy: String?
    var usedAt: Date?

    var isUsed: Bool { usedBy != nil }
}

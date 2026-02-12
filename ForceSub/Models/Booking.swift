import Foundation
import FirebaseFirestore

enum BookingStatus: String, Codable {
    case confirmed
    case cancelled
}

struct Booking: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let classId: String
    let className: String
    let instructor: String
    let classDateTime: Date
    let classDurationMinutes: Int
    let classLevel: ClassLevel
    let location: String
    let bookedAt: Date
    var status: BookingStatus
}

import Foundation
import FirebaseFirestore

struct GymClass: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let name: String
    let instructor: String
    let dateTime: Date
    let durationMinutes: Int
    let level: String
    let description: String
    let location: String
    let totalSpots: Int
    var bookedCount: Int

    var availableSpots: Int {
        max(0, totalSpots - bookedCount)
    }

    var isFull: Bool {
        availableSpots == 0
    }

    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: durationMinutes, to: dateTime) ?? dateTime
    }

    // Hashable conformance (needed for NavigationStack destination)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GymClass, rhs: GymClass) -> Bool {
        lhs.id == rhs.id
    }
}

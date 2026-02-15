import Foundation
import FirebaseFirestore

enum ClassLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        rawValue.capitalized
    }
}

struct GymClass: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
    var instructor: String
    var dateTime: Date
    var durationMinutes: Int
    var level: ClassLevel
    var description: String
    var location: String
    var totalSpots: Int
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

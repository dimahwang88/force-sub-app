import Foundation
import FirebaseFirestore

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
    /// Download URL for the post-training group photo stored in Firebase Storage
    var groupPhotoURL: String?

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

    // MARK: - Custom Codable

    enum CodingKeys: String, CodingKey {
        case id, name, instructor, dateTime, durationMinutes, level
        case description, location, totalSpots, bookedCount, groupPhotoURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        name = try container.decode(String.self, forKey: .name)
        instructor = try container.decode(String.self, forKey: .instructor)
        dateTime = try container.decode(Date.self, forKey: .dateTime)
        level = try container.decode(ClassLevel.self, forKey: .level)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        location = try container.decode(String.self, forKey: .location)
        groupPhotoURL = try container.decodeIfPresent(String.self, forKey: .groupPhotoURL)

        // Firestore stores all JS numbers as doubles — handle both Int and Double
        durationMinutes = Self.decodeInt(from: container, forKey: .durationMinutes) ?? 60
        totalSpots = Self.decodeInt(from: container, forKey: .totalSpots) ?? 30
        bookedCount = Self.decodeInt(from: container, forKey: .bookedCount) ?? 0
    }

    init(name: String, instructor: String, dateTime: Date, durationMinutes: Int,
         level: ClassLevel, description: String, location: String,
         totalSpots: Int, bookedCount: Int, groupPhotoURL: String? = nil) {
        self.name = name
        self.instructor = instructor
        self.dateTime = dateTime
        self.durationMinutes = durationMinutes
        self.level = level
        self.description = description
        self.location = location
        self.totalSpots = totalSpots
        self.bookedCount = bookedCount
        self.groupPhotoURL = groupPhotoURL
    }

    /// Decode a number field as Int, handling both Int and Double storage.
    private static func decodeInt(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        if let intVal = try? container.decode(Int.self, forKey: key) {
            return intVal
        }
        if let doubleVal = try? container.decode(Double.self, forKey: key) {
            return Int(doubleVal)
        }
        return nil
    }
}

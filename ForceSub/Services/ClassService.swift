import Foundation
import FirebaseFirestore

enum ScheduleError: LocalizedError {
    case scheduleExpired(lastClassDate: Date)

    var errorDescription: String? {
        switch self {
        case .scheduleExpired(let date):
            return "Schedule ended on \(date.formattedShort). Tap Extend to generate new classes."
        }
    }
}

final class ClassService {
    private let db = Firestore.firestore()
    private let collectionName = "classes"

    func fetchClasses(for date: Date) async throws -> [GymClass] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        print("📅 Fetching classes for \(startOfDay) to \(endOfDay)")

        let snapshot = try await db.collection(collectionName)
            .whereField("dateTime", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("dateTime", isLessThan: Timestamp(date: endOfDay))
            .order(by: "dateTime")
            .getDocuments()

        print("📅 Found \(snapshot.documents.count) documents")

        // If no docs for this day, check what dates exist at all
        if snapshot.documents.isEmpty {
            let allSnapshot = try await db.collection(collectionName)
                .order(by: "dateTime", descending: true)
                .limit(to: 1)
                .getDocuments()
            if let mostRecentData = allSnapshot.documents.first?.data(),
               let mostRecentTimestamp = mostRecentData["dateTime"] as? Timestamp {
                let mostRecentDate = mostRecentTimestamp.dateValue()
                print("📅 Most recent class: \(mostRecentDate)")
                if mostRecentDate < startOfDay {
                    throw ScheduleError.scheduleExpired(lastClassDate: mostRecentDate)
                }
            }
        }

        var decoded: [GymClass] = []
        var decodeErrors: [String] = []

        for doc in snapshot.documents {
            do {
                let gymClass = try doc.data(as: GymClass.self)
                decoded.append(gymClass)
            } catch {
                let data = doc.data()
                let fields = data.map { "\($0.key): \(type(of: $0.value))=\($0.value)" }.joined(separator: ", ")
                print("⚠️ Failed to decode class \(doc.documentID): \(error)\n   Fields: \(fields)")
                decodeErrors.append("\(doc.documentID): \(error.localizedDescription)")
            }
        }

        // If we found documents but couldn't decode any, throw so the UI shows an error
        if !snapshot.documents.isEmpty && decoded.isEmpty {
            let summary = decodeErrors.prefix(3).joined(separator: "\n")
            throw NSError(
                domain: "ClassService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Found \(snapshot.documents.count) classes but failed to decode them.\n\(summary)"]
            )
        }

        return decoded
    }

    func fetchClass(id: String) async throws -> GymClass? {
        let doc = try await db.collection(collectionName).document(id).getDocument()
        do {
            return try doc.data(as: GymClass.self)
        } catch {
            print("⚠️ Failed to decode class \(doc.documentID): \(error)")
            return nil
        }
    }

    func addClass(_ gymClass: GymClass) async throws {
        try db.collection(collectionName).addDocument(from: gymClass)
    }

    func updateClass(_ gymClass: GymClass) async throws {
        guard let id = gymClass.id else { return }
        try db.collection(collectionName).document(id).setData(from: gymClass, merge: true)
    }

    func deleteClass(id: String) async throws {
        try await db.collection(collectionName).document(id).delete()
    }

    /// Extends the schedule by filling in missing classes for the next 14 days
    /// based on the weekly template derived from existing classes.
    /// Only creates classes that don't already exist (no duplicates).
    /// Returns the number of new classes created.
    func extendSchedule() async throws -> Int {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        // Step 1: Fetch existing classes to build a weekly template
        let allSnapshot = try await db.collection(collectionName)
            .order(by: "dateTime", descending: true)
            .limit(to: 100)
            .getDocuments()

        let allClasses = allSnapshot.documents.compactMap { doc in
            try? doc.data(as: GymClass.self)
        }

        if allClasses.isEmpty { return 0 }

        // Build template: unique classes by name + weekday + hour + minute
        var seen = Set<String>()
        var template: [(name: String, instructor: String, weekday: Int, hour: Int, minute: Int,
                         durationMinutes: Int, level: ClassLevel, description: String,
                         location: String, totalSpots: Int)] = []

        for cls in allClasses {
            let comps = calendar.dateComponents([.weekday, .hour, .minute], from: cls.dateTime)
            let key = "\(cls.name)|\(comps.weekday!)|\(comps.hour!)|\(comps.minute!)"
            if seen.insert(key).inserted {
                template.append((
                    name: cls.name, instructor: cls.instructor,
                    weekday: comps.weekday!, hour: comps.hour!, minute: comps.minute!,
                    durationMinutes: cls.durationMinutes, level: cls.level,
                    description: cls.description, location: cls.location,
                    totalSpots: cls.totalSpots
                ))
            }
        }

        print("📅 Template has \(template.count) unique class slots")

        // Step 2: For each of the next 14 days, check what already exists
        // and only create missing classes
        var createdCount = 0

        for dayOffset in 0..<14 {
            guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: todayStart) else { continue }
            let targetWeekday = calendar.component(.weekday, from: targetDay)

            // Get slots for this weekday
            let daySlots = template.filter { $0.weekday == targetWeekday }
            if daySlots.isEmpty { continue }

            // Fetch existing classes for this day
            let dayStart = calendar.startOfDay(for: targetDay)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            let existingSnapshot = try await db.collection(collectionName)
                .whereField("dateTime", isGreaterThanOrEqualTo: Timestamp(date: dayStart))
                .whereField("dateTime", isLessThan: Timestamp(date: dayEnd))
                .getDocuments()

            // Build set of existing class keys (name + hour + minute)
            let existingKeys = Set(existingSnapshot.documents.compactMap { doc -> String? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let ts = data["dateTime"] as? Timestamp else { return nil }
                let comps = calendar.dateComponents([.hour, .minute], from: ts.dateValue())
                return "\(name)|\(comps.hour!)|\(comps.minute!)"
            })

            let batch = db.batch()
            var batchCount = 0

            for slot in daySlots {
                let slotKey = "\(slot.name)|\(slot.hour)|\(slot.minute)"

                // Skip if this class already exists for this day
                if existingKeys.contains(slotKey) { continue }

                var comps = calendar.dateComponents([.year, .month, .day], from: targetDay)
                comps.hour = slot.hour
                comps.minute = slot.minute
                comps.second = 0
                guard let classDateTime = calendar.date(from: comps) else { continue }

                // Skip if in the past
                if classDateTime < now { continue }

                let newClass = GymClass(
                    name: slot.name,
                    instructor: slot.instructor,
                    dateTime: classDateTime,
                    durationMinutes: slot.durationMinutes,
                    level: slot.level,
                    description: slot.description,
                    location: slot.location,
                    totalSpots: slot.totalSpots,
                    bookedCount: 0
                )

                let ref = db.collection(collectionName).document()
                try batch.setData(from: newClass, forDocument: ref)
                batchCount += 1
            }

            if batchCount > 0 {
                try await batch.commit()
                createdCount += batchCount
            }
        }

        print("📅 Created \(createdCount) new classes (skipped existing)")
        return createdCount
    }
}

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

    /// Fetches the most recent week that has classes and rebuilds the schedule
    /// for the current and next week. Deletes all future unbooked classes first
    /// to ensure a clean slate (no duplicates). Returns the number of classes created.
    func extendSchedule() async throws -> Int {
        let calendar = Calendar.current
        let now = Date()

        // Step 1: Fetch ALL classes to build a weekly template
        let allSnapshot = try await db.collection(collectionName)
            .order(by: "dateTime", descending: true)
            .limit(to: 100)
            .getDocuments()

        print("📅 extendSchedule: fetched \(allSnapshot.documents.count) total classes")

        let allClasses = allSnapshot.documents.compactMap { doc in
            try? doc.data(as: GymClass.self)
        }

        if allClasses.isEmpty { return 0 }

        // Build a template: unique classes by name + weekday + hour + minute
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

        // Step 2: Delete ALL future unbooked classes
        let futureSnapshot = try await db.collection(collectionName)
            .whereField("dateTime", isGreaterThanOrEqualTo: Timestamp(date: now))
            .getDocuments()

        print("📅 Found \(futureSnapshot.documents.count) future documents to check")

        var deletedCount = 0
        let toDelete = futureSnapshot.documents.filter { doc in
            let data = doc.data()
            // Keep classes that have bookings
            if let booked = data["bookedCount"] as? NSNumber, booked.intValue > 0 {
                return false
            }
            return true
        }

        for chunk in stride(from: 0, to: toDelete.count, by: 500) {
            let batch = db.batch()
            let end = min(chunk + 500, toDelete.count)
            for i in chunk..<end {
                batch.deleteDocument(toDelete[i].reference)
            }
            try await batch.commit()
            deletedCount += (end - chunk)
        }

        print("📅 Deleted \(deletedCount) future unbooked classes")

        // Step 3: Generate fresh classes for current week + next week
        let todayStart = calendar.startOfDay(for: now)
        var createdCount = 0

        // Generate for the next 14 days
        for dayOffset in 0..<14 {
            guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: todayStart) else { continue }
            let targetWeekday = calendar.component(.weekday, from: targetDay)

            let batch = db.batch()
            var batchCount = 0

            for slot in template {
                guard slot.weekday == targetWeekday else { continue }

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

        print("📅 Created \(createdCount) new classes")
        return createdCount
    }
}

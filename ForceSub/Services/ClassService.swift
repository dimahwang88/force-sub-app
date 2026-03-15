import Foundation
import FirebaseFirestore

final class ClassService {
    private let db = Firestore.firestore()
    private let collectionName = "classes"

    func fetchClasses(for date: Date) async throws -> [GymClass] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let snapshot = try await db.collection(collectionName)
            .whereField("dateTime", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("dateTime", isLessThan: Timestamp(date: endOfDay))
            .order(by: "dateTime")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            do {
                return try doc.data(as: GymClass.self)
            } catch {
                print("⚠️ Failed to decode class \(doc.documentID): \(error)")
                return nil
            }
        }
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

    /// Fetches the most recent week that has classes and duplicates them
    /// into the current week and the next week, resetting bookedCount to 0.
    /// Returns the number of classes created.
    func extendSchedule() async throws -> Int {
        // Find the most recent class to determine the source week
        let recentSnapshot = try await db.collection(collectionName)
            .order(by: "dateTime", descending: true)
            .limit(to: 1)
            .getDocuments()

        guard let mostRecentDoc = recentSnapshot.documents.first,
              let mostRecent = try? mostRecentDoc.data(as: GymClass.self) else {
            return 0
        }

        // Get the full week of the most recent class (Mon–Sun)
        let calendar = Calendar.current
        let sourceWeekStart = calendar.dateInterval(of: .weekOfYear, for: mostRecent.dateTime)!.start
        let sourceWeekEnd = calendar.date(byAdding: .day, value: 7, to: sourceWeekStart)!

        let weekSnapshot = try await db.collection(collectionName)
            .whereField("dateTime", isGreaterThanOrEqualTo: Timestamp(date: sourceWeekStart))
            .whereField("dateTime", isLessThan: Timestamp(date: sourceWeekEnd))
            .getDocuments()

        let sourceClasses = weekSnapshot.documents.compactMap { doc in
            try? doc.data(as: GymClass.self)
        }

        if sourceClasses.isEmpty { return 0 }

        // Calculate current week start
        let today = Date()
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)!.start

        // Determine which weeks to fill (current week + next week)
        let targetWeekStarts = [
            currentWeekStart,
            calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)!
        ]

        var createdCount = 0
        let batch = db.batch()

        for targetStart in targetWeekStarts {
            // Skip if target week is the same as source week
            if calendar.isDate(targetStart, equalTo: sourceWeekStart, toGranularity: .weekOfYear) {
                continue
            }

            let dayOffset = calendar.dateComponents([.day], from: sourceWeekStart, to: targetStart).day!

            for source in sourceClasses {
                let newDateTime = calendar.date(byAdding: .day, value: dayOffset, to: source.dateTime)!

                // Skip classes in the past
                if newDateTime < today { continue }

                let newClass = GymClass(
                    name: source.name,
                    instructor: source.instructor,
                    dateTime: newDateTime,
                    durationMinutes: source.durationMinutes,
                    level: source.level,
                    description: source.description,
                    location: source.location,
                    totalSpots: source.totalSpots,
                    bookedCount: 0
                )

                let ref = db.collection(collectionName).document()
                try batch.setData(from: newClass, forDocument: ref)
                createdCount += 1
            }
        }

        if createdCount > 0 {
            try await batch.commit()
        }

        return createdCount
    }
}

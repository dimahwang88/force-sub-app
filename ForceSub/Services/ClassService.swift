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
            try? doc.data(as: GymClass.self)
        }
    }

    func fetchClass(id: String) async throws -> GymClass? {
        let doc = try await db.collection(collectionName).document(id).getDocument()
        return try? doc.data(as: GymClass.self)
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
}

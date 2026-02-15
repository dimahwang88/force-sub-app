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
}

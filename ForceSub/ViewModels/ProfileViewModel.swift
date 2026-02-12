import Foundation
import Observation
import FirebaseFirestore

@Observable
final class ProfileViewModel {
    var user: AppUser?
    var isLoading = false
    var errorMessage: String?

    private let db = Firestore.firestore()

    func loadProfile(userId: String) async {
        isLoading = true
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            user = try? doc.data(as: AppUser.self)
        } catch {
            errorMessage = "Failed to load profile."
        }
        isLoading = false
    }
}

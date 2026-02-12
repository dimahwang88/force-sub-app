import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    func listenToAuthState(handler: @escaping (String?) -> Void) {
        authStateHandle = auth.addStateDidChangeListener { _, user in
            handler(user?.uid)
        }
    }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func signUp(email: String, password: String, displayName: String) async throws -> String {
        let result = try await auth.createUser(withEmail: email, password: password)
        let userId = result.user.uid

        let user = AppUser(
            email: email,
            displayName: displayName,
            createdAt: Date()
        )
        try db.collection("users").document(userId).setData(from: user)

        return userId
    }

    func signOut() throws {
        try auth.signOut()
    }

    func fetchUser(userId: String) async throws -> AppUser? {
        let doc = try await db.collection("users").document(userId).getDocument()
        return try? doc.data(as: AppUser.self)
    }

    var currentUserId: String? {
        auth.currentUser?.uid
    }
}

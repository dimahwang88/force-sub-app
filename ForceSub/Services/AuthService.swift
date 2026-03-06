import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AuthError: LocalizedError {
    case invalidAdminCode

    var errorDescription: String? {
        switch self {
        case .invalidAdminCode:
            return "Invalid or expired admin invite code."
        }
    }
}

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

    func signUp(email: String, password: String, displayName: String, adminCode: String? = nil) async throws -> String {
        var accountType: AccountType = .customer

        // Validate admin invite code before creating the account
        if let code = adminCode, !code.isEmpty {
            let valid = try await validateAdminCode(code)
            guard valid else { throw AuthError.invalidAdminCode }
            accountType = .admin
        }

        let result = try await auth.createUser(withEmail: email, password: password)
        let userId = result.user.uid

        let user = AppUser(
            email: email,
            displayName: displayName,
            createdAt: Date(),
            isAdmin: accountType == .admin,
            accountType: accountType.rawValue
        )
        try db.collection("users").document(userId).setData(from: user)

        // Mark the invite code as used
        if let code = adminCode, !code.isEmpty {
            try? await db.collection("adminCodes").document(code).updateData([
                "usedBy": userId,
                "usedAt": FieldValue.serverTimestamp()
            ])
        }

        return userId
    }

    func signOut() throws {
        try auth.signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func fetchUser(userId: String) async throws -> AppUser? {
        let doc = try await db.collection("users").document(userId).getDocument()
        return try? doc.data(as: AppUser.self)
    }

    var currentUserId: String? {
        auth.currentUser?.uid
    }

    // MARK: - Admin Bootstrap

    /// Returns true if at least one admin user exists in Firestore.
    /// Uses a dedicated metadata document that any authenticated user can read,
    /// avoiding permission issues with querying the users collection.
    func hasAnyAdmin() async throws -> Bool {
        let doc = try await db.collection("metadata").document("adminBootstrap").getDocument()
        guard let data = doc.data() else { return false }
        return data["adminExists"] as? Bool ?? false
    }

    /// Promote a user to admin. Only succeeds when no admins exist yet (bootstrap).
    func promoteToAdmin(userId: String) async throws {
        let adminExists = try await hasAnyAdmin()
        guard !adminExists else {
            throw AuthError.invalidAdminCode
        }
        try await db.collection("users").document(userId).updateData([
            "isAdmin": true,
            "accountType": AccountType.admin.rawValue
        ])
        // Mark that an admin now exists so future bootstrap attempts are blocked
        try await db.collection("metadata").document("adminBootstrap").setData([
            "adminExists": true,
            "firstAdminUserId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    /// Promote an existing user to admin using a valid invite code.
    func promoteWithCode(userId: String, code: String) async throws {
        let valid = try await validateAdminCode(code)
        guard valid else { throw AuthError.invalidAdminCode }

        try await db.collection("users").document(userId).updateData([
            "isAdmin": true,
            "accountType": AccountType.admin.rawValue
        ])

        // Mark the invite code as used
        try? await db.collection("adminCodes").document(code).updateData([
            "usedBy": userId,
            "usedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Private

    /// Check that the code exists in `adminCodes` collection and hasn't been used yet.
    private func validateAdminCode(_ code: String) async throws -> Bool {
        let doc = try await db.collection("adminCodes").document(code).getDocument()
        guard let data = doc.data() else { return false }
        // Code is invalid if it's already been used
        return data["usedBy"] == nil
    }
}

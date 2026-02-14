import Foundation
import FirebaseAuth
import Observation

@Observable
final class AuthViewModel {
    var isAuthenticated = false
    var currentUserId: String?
    var currentUser: AppUser?
    var isLoading = false
    var errorMessage: String?

    private let authService = AuthService()

    init() {
        authService.listenToAuthState { [weak self] userId in
            guard let self else { return }
            self.isAuthenticated = userId != nil
            self.currentUserId = userId
            if let userId {
                Task { await self.fetchUserProfile(userId: userId) }
            } else {
                self.currentUser = nil
            }
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
        isLoading = false
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
        isLoading = false
    }

    private static func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        print("[Auth Error] code: \(nsError.code), domain: \(nsError.domain), description: \(nsError.localizedDescription), userInfo: \(nsError.userInfo)")

        guard let code = AuthErrorCode.Code(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .wrongPassword, .invalidCredential:
            return "Incorrect email or password."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection."
        default:
            return error.localizedDescription
        }
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchUserProfile(userId: String) async {
        do {
            currentUser = try await authService.fetchUser(userId: userId)
        } catch {
            // Profile fetch failure is non-critical; auth state still works
        }
    }
}

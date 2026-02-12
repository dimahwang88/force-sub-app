import Foundation
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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }
        isLoading = false
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

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.currentUser?.resolvedAccountType == .admin {
                    AdminTabView()
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: authViewModel.currentUser?.resolvedAccountType)
    }
}

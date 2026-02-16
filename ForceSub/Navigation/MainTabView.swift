import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    private var isAdmin: Bool {
        authViewModel.currentUser?.admin ?? false
    }

    var body: some View {
        TabView {
            Tab("Schedule", systemImage: "calendar") {
                NavigationStack {
                    ScheduleView()
                }
            }

            Tab("My Bookings", systemImage: "list.clipboard") {
                NavigationStack {
                    MyBookingsView()
                }
            }

            if isAdmin {
                Tab("Customers", systemImage: "person.2.fill") {
                    NavigationStack {
                        AdminCustomerListView()
                    }
                }
            }

            Tab("Profile", systemImage: "person.circle") {
                NavigationStack {
                    ProfileView()
                }
            }
        }
    }
}

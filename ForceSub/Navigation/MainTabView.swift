import SwiftUI

struct MainTabView: View {
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

            Tab("Profile", systemImage: "person.circle") {
                NavigationStack {
                    ProfileView()
                }
            }
        }
    }
}

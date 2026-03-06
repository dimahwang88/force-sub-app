import SwiftUI

struct AdminTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                NavigationStack {
                    AdminDashboardView()
                }
            }

            Tab("Schedule", systemImage: "calendar") {
                NavigationStack {
                    ScheduleView()
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

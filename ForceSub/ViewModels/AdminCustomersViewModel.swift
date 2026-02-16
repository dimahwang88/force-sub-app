import Foundation
import Observation

struct CustomerSummary: Identifiable {
    let user: AppUser
    let totalClasses: Int
    let totalMinutes: Int
    let lastClassDate: Date?

    var id: String { user.id ?? "" }

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }
}

@Observable
final class AdminCustomersViewModel {
    var customers: [CustomerSummary] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""

    private let authService = AuthService()
    private let bookingService = BookingService()

    var filteredCustomers: [CustomerSummary] {
        guard !searchText.isEmpty else { return customers }
        let query = searchText.lowercased()
        return customers.filter {
            $0.user.displayName.lowercased().contains(query) ||
            $0.user.email.lowercased().contains(query)
        }
    }

    func loadCustomers() async {
        isLoading = true
        errorMessage = nil
        do {
            async let usersTask = authService.fetchAllUsers()
            async let bookingsTask = bookingService.fetchAllBookings()
            let (users, allBookings) = try await (usersTask, bookingsTask)

            let now = Date()
            let pastBookings = allBookings.filter { $0.classDateTime < now }
            let bookingsByUser = Dictionary(grouping: pastBookings, by: { $0.userId })

            customers = users
                .filter { !($0.isAdmin ?? false) }
                .map { user in
                    let userBookings = bookingsByUser[user.id ?? ""] ?? []
                    return CustomerSummary(
                        user: user,
                        totalClasses: userBookings.count,
                        totalMinutes: userBookings.reduce(0) { $0 + $1.classDurationMinutes },
                        lastClassDate: userBookings.map(\.classDateTime).max()
                    )
                }
                .sorted { $0.user.displayName.localizedCaseInsensitiveCompare($1.user.displayName) == .orderedAscending }
        } catch {
            errorMessage = "Failed to load customers."
        }
        isLoading = false
    }
}

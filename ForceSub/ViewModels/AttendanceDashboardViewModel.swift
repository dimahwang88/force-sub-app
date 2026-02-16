import Foundation
import Observation

struct ClassBreakdown: Identifiable {
    let id = UUID()
    let className: String
    let count: Int
    let totalMinutes: Int

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }
}

@Observable
final class AttendanceDashboardViewModel {
    var attendedBookings: [Booking] = []
    var isLoading = false
    var errorMessage: String?

    private let bookingService = BookingService()

    // MARK: - Computed Stats

    var totalClasses: Int {
        attendedBookings.count
    }

    var totalMinutes: Int {
        attendedBookings.reduce(0) { $0 + $1.classDurationMinutes }
    }

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    var classBreakdown: [ClassBreakdown] {
        let grouped = Dictionary(grouping: attendedBookings, by: { $0.className })
        return grouped.map { name, bookings in
            ClassBreakdown(
                className: name,
                count: bookings.count,
                totalMinutes: bookings.reduce(0) { $0 + $1.classDurationMinutes }
            )
        }
        .sorted { $0.count > $1.count }
    }

    /// Number of calendar weeks spanned from first attended class to now.
    private var weeksSpanned: Double {
        guard let earliest = attendedBookings.map(\.classDateTime).min() else { return 1 }
        let days = max(Calendar.current.dateComponents([.day], from: earliest, to: Date()).day ?? 1, 1)
        return max(Double(days) / 7.0, 1)
    }

    /// Number of calendar months spanned from first attended class to now.
    private var monthsSpanned: Double {
        guard let earliest = attendedBookings.map(\.classDateTime).min() else { return 1 }
        let months = Calendar.current.dateComponents([.month], from: earliest, to: Date()).month ?? 1
        return max(Double(months), 1)
    }

    var averageClassesPerWeek: Double {
        Double(totalClasses) / weeksSpanned
    }

    var averageClassesPerMonth: Double {
        Double(totalClasses) / monthsSpanned
    }

    var averageHoursPerWeek: Double {
        totalHours / weeksSpanned
    }

    var averageHoursPerMonth: Double {
        totalHours / monthsSpanned
    }

    // MARK: - Data Loading

    func loadAttendance(userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let all = try await bookingService.fetchBookings(userId: userId)
            attendedBookings = all.filter { $0.classDateTime < Date() }
        } catch {
            errorMessage = "Failed to load attendance data."
        }
        isLoading = false
    }
}

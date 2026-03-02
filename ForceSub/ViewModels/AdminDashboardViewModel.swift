import Foundation
import Observation

@Observable
final class AdminDashboardViewModel {
    var customers: [AppUser] = []
    var allBookings: [Booking] = []
    var adminCodes: [AdminCode] = []
    var isLoading = false
    var errorMessage: String?
    var generatedCode: String?

    private let adminService = AdminService()
    private let calendar = Calendar.current

    // MARK: - Computed Stats

    var totalCustomers: Int { customers.count }

    var totalClassesAttended: Int {
        allBookings.filter { $0.classDateTime < Date() }.count
    }

    var upcomingBookingsCount: Int {
        allBookings.filter { $0.classDateTime >= Date() }.count
    }

    /// Attendance per customer: userId -> (displayName, attended count, upcoming count)
    var customerAttendance: [CustomerAttendanceRow] {
        let now = Date()
        var map: [String: CustomerAttendanceRow] = [:]

        // Initialize from customer list
        for customer in customers {
            guard let id = customer.id else { continue }
            map[id] = CustomerAttendanceRow(
                userId: id,
                displayName: customer.displayName,
                email: customer.email,
                beltRank: customer.beltRank,
                attendedCount: 0,
                upcomingCount: 0,
                lastAttendedDate: nil
            )
        }

        // Populate from bookings
        for booking in allBookings {
            if booking.classDateTime < now {
                map[booking.userId]?.attendedCount += 1
                if let current = map[booking.userId]?.lastAttendedDate {
                    if booking.classDateTime > current {
                        map[booking.userId]?.lastAttendedDate = booking.classDateTime
                    }
                } else {
                    map[booking.userId]?.lastAttendedDate = booking.classDateTime
                }
            } else {
                map[booking.userId]?.upcomingCount += 1
            }
        }

        return map.values.sorted { $0.attendedCount > $1.attendedCount }
    }

    /// Attendance per day for the last 30 days (for the chart).
    var dailyAttendance: [DailyAttendance] {
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now))!

        var dayMap: [Date: Int] = [:]
        for i in 0..<30 {
            let day = calendar.date(byAdding: .day, value: i, to: startDate)!
            dayMap[day] = 0
        }

        for booking in allBookings where booking.classDateTime < now {
            let day = calendar.startOfDay(for: booking.classDateTime)
            if day >= startDate {
                dayMap[day, default: 0] += 1
            }
        }

        return dayMap.sorted { $0.key < $1.key }
            .map { DailyAttendance(date: $0.key, count: $0.value) }
    }

    /// Attendance by class name.
    var classPopularity: [ClassPopularity] {
        var map: [String: Int] = [:]
        for booking in allBookings where booking.classDateTime < Date() {
            map[booking.className, default: 0] += 1
        }
        return map.sorted { $0.value > $1.value }
            .map { ClassPopularity(className: $0.key, count: $0.value) }
    }

    // MARK: - Load Data

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        do {
            async let customersTask = adminService.fetchAllCustomers()
            async let bookingsTask = adminService.fetchAllBookings()
            async let codesTask = adminService.fetchAdminCodes()
            customers = try await customersTask
            allBookings = try await bookingsTask
            adminCodes = try await codesTask
        } catch {
            errorMessage = "Failed to load dashboard data."
        }
        isLoading = false
    }

    // MARK: - Admin Invite Codes

    func generateInviteCode(createdBy: String) async {
        generatedCode = nil
        do {
            let code = try await adminService.generateAdminCode(createdBy: createdBy)
            generatedCode = code
            adminCodes = try await adminService.fetchAdminCodes()
        } catch {
            errorMessage = "Failed to generate invite code."
        }
    }

    func deleteInviteCode(_ code: String) async {
        do {
            try await adminService.deleteAdminCode(code)
            adminCodes.removeAll { $0.id == code }
        } catch {
            errorMessage = "Failed to delete invite code."
        }
    }
}

// MARK: - Supporting Types

struct CustomerAttendanceRow: Identifiable {
    let userId: String
    var displayName: String
    var email: String
    var beltRank: String?
    var attendedCount: Int
    var upcomingCount: Int
    var lastAttendedDate: Date?

    var id: String { userId }
}

struct DailyAttendance: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct ClassPopularity: Identifiable {
    let className: String
    let count: Int
    var id: String { className }
}

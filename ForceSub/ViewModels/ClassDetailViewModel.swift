import Foundation
import Observation

@Observable
final class ClassDetailViewModel {
    var gymClass: GymClass
    var existingBooking: Booking?
    var isLoading = false
    var errorMessage: String?
    var bookingSucceeded = false
    var cancellationSucceeded = false

    private let bookingService = BookingService()
    private let classService = ClassService()

    var isBooked: Bool {
        existingBooking != nil
    }

    init(gymClass: GymClass) {
        self.gymClass = gymClass
    }

    func checkExistingBooking(userId: String) async {
        guard let classId = gymClass.id else { return }
        do {
            existingBooking = try await bookingService.existingBooking(
                userId: userId,
                classId: classId
            )
        } catch {
            // Non-critical: if the check fails, user can still try to book
        }
    }

    func bookClass(userId: String) async {
        isLoading = true
        errorMessage = nil
        bookingSucceeded = false
        do {
            existingBooking = try await bookingService.bookClass(
                gymClass: gymClass,
                userId: userId
            )
            // Refresh class data to get updated bookedCount
            if let classId = gymClass.id,
               let updated = try await classService.fetchClass(id: classId) {
                gymClass = updated
            }
            bookingSucceeded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshClass() async {
        guard let classId = gymClass.id else { return }
        do {
            if let updated = try await classService.fetchClass(id: classId) {
                gymClass = updated
            }
        } catch {
            // Non-critical: keep showing existing data
        }
    }

    func cancelBooking() async {
        guard let booking = existingBooking else { return }
        isLoading = true
        errorMessage = nil
        cancellationSucceeded = false
        do {
            try await bookingService.cancelBooking(booking)
            existingBooking = nil
            // Refresh class data
            if let classId = gymClass.id,
               let updated = try await classService.fetchClass(id: classId) {
                gymClass = updated
            }
            cancellationSucceeded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

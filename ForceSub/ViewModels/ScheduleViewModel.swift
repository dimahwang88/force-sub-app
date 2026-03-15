import Foundation
import Observation

@Observable
final class ScheduleViewModel {
    var classesForSelectedDay: [GymClass] = []
    var weekDays: [Date] = []
    var isLoading = false
    var errorMessage: String?
    var isExtending = false
    var extendResult: String?

    private let classService = ClassService()

    init() {
        weekDays = Date.nextDays(7)
    }

    func loadClasses(for date: Date) async {
        isLoading = true
        errorMessage = nil
        do {
            classesForSelectedDay = try await classService.fetchClasses(for: date)
        } catch {
            errorMessage = "Failed to load classes."
            classesForSelectedDay = []
        }
        isLoading = false
    }

    func extendSchedule() async {
        isExtending = true
        extendResult = nil
        do {
            let count = try await classService.extendSchedule()
            if count > 0 {
                extendResult = "Created \(count) classes for this week and next."
            } else {
                extendResult = "No new classes to create — schedule may already be current."
            }
        } catch {
            extendResult = "Failed to extend schedule: \(error.localizedDescription)"
        }
        isExtending = false
    }
}

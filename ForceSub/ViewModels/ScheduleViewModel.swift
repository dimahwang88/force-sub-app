import Foundation
import Observation

@Observable
final class ScheduleViewModel {
    var classesForSelectedDay: [GymClass] = []
    var weekDays: [Date] = []
    var isLoading = false
    var errorMessage: String?
    var needsExtend = false
    var isExtending = false
    var extendResult: String?

    private let classService = ClassService()

    init() {
        weekDays = Date.nextDays(7)
    }

    func loadClasses(for date: Date) async {
        isLoading = true
        errorMessage = nil
        needsExtend = false
        do {
            classesForSelectedDay = try await classService.fetchClasses(for: date)
        } catch let error as ScheduleError {
            needsExtend = true
            errorMessage = error.localizedDescription
            classesForSelectedDay = []
        } catch {
            errorMessage = error.localizedDescription
            classesForSelectedDay = []
        }
        isLoading = false
    }

    func extendSchedule() async {
        isExtending = true
        extendResult = nil
        do {
            // Clean up any existing duplicates first
            let removed = try await classService.removeDuplicates()

            let count = try await classService.extendSchedule()
            if count > 0 {
                var message = "Created \(count) classes for this week and next."
                if removed > 0 {
                    message += " Removed \(removed) duplicates."
                }
                extendResult = message
            } else if removed > 0 {
                extendResult = "Removed \(removed) duplicate classes."
            } else {
                extendResult = "No new classes to create — schedule may already be current."
            }
        } catch {
            extendResult = "Failed to extend schedule: \(error.localizedDescription)"
        }
        isExtending = false
    }
}

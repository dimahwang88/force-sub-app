import Foundation
import Observation

@Observable
final class ScheduleViewModel {
    var classesForSelectedDay: [GymClass] = []
    var weekDays: [Date] = []
    var isLoading = false
    var errorMessage: String?

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
}

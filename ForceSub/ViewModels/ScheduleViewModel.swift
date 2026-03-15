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
            let fetched = try await classService.fetchClasses(for: date)

            // Deduplicate: keep only one class per name + time slot
            var seen = Set<String>()
            let unique = fetched.filter { cls in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: cls.dateTime)
                let key = "\(cls.name)|\(comps.hour!)|\(comps.minute!)"
                return seen.insert(key).inserted
            }

            classesForSelectedDay = unique
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

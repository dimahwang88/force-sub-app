import Foundation
import Observation

@Observable
final class EditClassViewModel {
    var name = ""
    var instructor = ""
    var dateTime = Date()
    var durationMinutes = 60
    var level: ClassLevel = .beginner
    var description = ""
    var location = ""
    var totalSpots = 20
    var isLoading = false
    var errorMessage: String?
    var didSave = false
    var didDelete = false

    private let classService = ClassService()
    private var existingClass: GymClass?

    var isEditing: Bool {
        existingClass != nil
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !instructor.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty &&
        totalSpots > 0 &&
        durationMinutes > 0
    }

    init(gymClass: GymClass? = nil) {
        if let gymClass {
            existingClass = gymClass
            name = gymClass.name
            instructor = gymClass.instructor
            dateTime = gymClass.dateTime
            durationMinutes = gymClass.durationMinutes
            level = gymClass.level
            description = gymClass.description
            location = gymClass.location
            totalSpots = gymClass.totalSpots
        }
    }

    func save() async {
        isLoading = true
        errorMessage = nil
        do {
            if var existing = existingClass {
                existing.name = name.trimmingCharacters(in: .whitespaces)
                existing.instructor = instructor.trimmingCharacters(in: .whitespaces)
                existing.dateTime = dateTime
                existing.durationMinutes = durationMinutes
                existing.level = level
                existing.description = description.trimmingCharacters(in: .whitespaces)
                existing.location = location.trimmingCharacters(in: .whitespaces)
                existing.totalSpots = totalSpots
                try await classService.updateClass(existing)
            } else {
                let newClass = GymClass(
                    name: name.trimmingCharacters(in: .whitespaces),
                    instructor: instructor.trimmingCharacters(in: .whitespaces),
                    dateTime: dateTime,
                    durationMinutes: durationMinutes,
                    level: level,
                    description: description.trimmingCharacters(in: .whitespaces),
                    location: location.trimmingCharacters(in: .whitespaces),
                    totalSpots: totalSpots,
                    bookedCount: 0
                )
                try await classService.addClass(newClass)
            }
            didSave = true
        } catch {
            errorMessage = "Failed to save class: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func deleteClass() async {
        guard let id = existingClass?.id else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await classService.deleteClass(id: id)
            didDelete = true
        } catch {
            errorMessage = "Failed to delete class: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

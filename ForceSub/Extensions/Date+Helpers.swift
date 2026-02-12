import Foundation

extension Date {
    /// Formatted time string like "6:00 PM"
    var formattedTime: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// Formatted date string like "Mon, Jan 15"
    var formattedShort: String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// Formatted date and time like "Mon, Jan 15 at 6:00 PM"
    var formattedDateTime: String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
    }

    /// Day of week abbreviation like "Mon"
    var dayAbbreviation: String {
        formatted(.dateTime.weekday(.abbreviated))
    }

    /// Day number like "15"
    var dayNumber: String {
        formatted(.dateTime.day())
    }

    /// Returns true if this date is in the past.
    var isPast: Bool {
        self < Date()
    }

    /// Generate an array of dates for the next N days starting from today.
    static func nextDays(_ count: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }
}

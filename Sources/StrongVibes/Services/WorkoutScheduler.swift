import Foundation

/// Pure scheduling logic for computing next workout dates.
struct WorkoutScheduler: Sendable {

    // MARK: - Public Interface

    /// Returns the next workout date on or after `startingFrom` that falls on one of `preferredDays`.
    ///
    /// - Parameters:
    ///   - lastWorkoutDate: The date the most recent workout was completed.
    ///   - preferredDays: Calendar weekday values (1=Sun…7=Sat).
    ///   - hour: Hour component for the notification time.
    ///   - minute: Minute component for the notification time.
    func nextWorkoutDate(
        after lastWorkoutDate: Date?,
        preferredDays: [Int],
        hour: Int,
        minute: Int,
        relativeTo referenceDate: Date = .now
    ) -> Date {
        let calendar = Calendar.current
        let startSearch: Date
        if let last = lastWorkoutDate {
            // Enforce at least one rest day between sessions.
            let dayAfter = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last)) ?? referenceDate
            startSearch = max(dayAfter, calendar.startOfDay(for: referenceDate))
        } else {
            startSearch = calendar.startOfDay(for: referenceDate)
        }

        return nextOccurrence(
            of: preferredDays,
            startingFrom: startSearch,
            hour: hour,
            minute: minute,
            using: calendar
        ) ?? startSearch
    }

    /// Returns whether a workout is due today given the next scheduled date.
    func isWorkoutDueToday(nextWorkoutDate: Date?, referenceDate: Date = .now) -> Bool {
        guard let next = nextWorkoutDate else { return true }
        return Calendar.current.isDate(next, inSameDayAs: referenceDate)
            || next <= referenceDate
    }

    // MARK: - Private

    private func nextOccurrence(
        of weekdays: [Int],
        startingFrom date: Date,
        hour: Int,
        minute: Int,
        using calendar: Calendar
    ) -> Date? {
        guard !weekdays.isEmpty else { return nil }
        var candidate = date
        for _ in 0..<14 {
            let weekday = calendar.component(.weekday, from: candidate)
            if weekdays.contains(weekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: candidate)
                components.hour = hour
                components.minute = minute
                components.second = 0
                return calendar.date(from: components)
            }
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return nil
    }
}

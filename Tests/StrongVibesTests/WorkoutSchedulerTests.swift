import Testing
import Foundation
@testable import StrongVibes

@Suite("WorkoutScheduler")
struct WorkoutSchedulerTests {

    let scheduler = WorkoutScheduler()
    // Monday = 2, Wednesday = 4, Friday = 6
    let monWedFri: [Int] = [2, 4, 6]

    // Reference: 2026-06-01 is a Monday
    let monday = Date.from(year: 2026, month: 6, day: 1)!
    let tuesday = Date.from(year: 2026, month: 6, day: 2)!
    let wednesday = Date.from(year: 2026, month: 6, day: 3)!
    let friday = Date.from(year: 2026, month: 6, day: 5)!
    let saturday = Date.from(year: 2026, month: 6, day: 6)!

    @Test("Returns today when no prior workout and today is a preferred day")
    func noLastWorkoutTodayIsPreferredDay() {
        let result = scheduler.nextWorkoutDate(
            after: nil,
            preferredDays: monWedFri,
            hour: 9,
            minute: 0,
            relativeTo: monday
        )
        #expect(Calendar.current.isDate(result, inSameDayAs: monday))
    }

    @Test("Skips to next preferred day when today is not a preferred day")
    func noLastWorkoutTodayIsNotPreferredDay() {
        let result = scheduler.nextWorkoutDate(
            after: nil,
            preferredDays: monWedFri,
            hour: 9,
            minute: 0,
            relativeTo: tuesday
        )
        #expect(Calendar.current.isDate(result, inSameDayAs: wednesday))
    }

    @Test("Enforces at least one rest day after a workout")
    func restDayEnforced() {
        let result = scheduler.nextWorkoutDate(
            after: monday,
            preferredDays: monWedFri,
            hour: 9,
            minute: 0,
            relativeTo: monday
        )
        // Monday workout → next is Wednesday (not Tuesday which isn't preferred)
        #expect(Calendar.current.isDate(result, inSameDayAs: wednesday))
    }

    @Test("Schedules at specified notification hour and minute")
    func notificationTimeIsPreserved() {
        let result = scheduler.nextWorkoutDate(
            after: nil,
            preferredDays: monWedFri,
            hour: 7,
            minute: 30,
            relativeTo: monday
        )
        let components = Calendar.current.dateComponents([.hour, .minute], from: result)
        #expect(components.hour == 7)
        #expect(components.minute == 30)
    }

    @Test("After Friday workout, next is Monday of following week")
    func wrapAroundWeekend() {
        let result = scheduler.nextWorkoutDate(
            after: friday,
            preferredDays: monWedFri,
            hour: 9,
            minute: 0,
            relativeTo: friday
        )
        let nextMonday = Date.from(year: 2026, month: 6, day: 8)!
        #expect(Calendar.current.isDate(result, inSameDayAs: nextMonday))
    }

    @Test("isWorkoutDueToday returns true when next workout is today")
    func dueToday() {
        #expect(scheduler.isWorkoutDueToday(nextWorkoutDate: monday, referenceDate: monday))
    }

    @Test("isWorkoutDueToday returns true when next workout date is in the past")
    func overdue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: monday)!
        #expect(scheduler.isWorkoutDueToday(nextWorkoutDate: yesterday, referenceDate: monday))
    }

    @Test("isWorkoutDueToday returns false when next workout is in the future")
    func notDueYet() {
        #expect(!scheduler.isWorkoutDueToday(nextWorkoutDate: wednesday, referenceDate: monday))
    }

    @Test("isWorkoutDueToday returns true when no date is scheduled")
    func noDateScheduled() {
        #expect(scheduler.isWorkoutDueToday(nextWorkoutDate: nil, referenceDate: monday))
    }
}

// MARK: - Test Helpers

extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)
    }
}

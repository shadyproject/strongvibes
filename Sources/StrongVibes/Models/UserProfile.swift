import Foundation
import SwiftData

/// Singleton model storing the user's program state and preferences.
@Model
final class UserProfile {

    // MARK: - Properties

    var experienceLevelRawValue: String
    var onboardingCompleted: Bool
    var nextWorkoutTypeRawValue: String
    var lastWorkoutDate: Date?
    var nextWorkoutDate: Date?
    var notificationHour: Int
    var notificationMinute: Int
    /// JSON-encoded `[String: Double]` mapping exercise name to current working weight.
    var currentWeightsData: Data
    /// JSON-encoded `[String: Int]` mapping exercise name to consecutive failure count.
    var failureCountsData: Data
    /// JSON-encoded `[Int]` of Calendar weekday values (1=Sun…7=Sat) for preferred workout days.
    var preferredWorkoutDaysData: Data

    // MARK: - Initialization

    init() {
        self.experienceLevelRawValue = LiftingExperience.newLifter.rawValue
        self.onboardingCompleted = false
        self.nextWorkoutTypeRawValue = WorkoutType.A.rawValue
        self.lastWorkoutDate = nil
        self.nextWorkoutDate = nil
        self.notificationHour = 9
        self.notificationMinute = 0
        self.currentWeightsData = Self.encode(ProgramConstants.newLifterStartingWeights)
        self.failureCountsData = Self.encode([String: Int]())
        // Default: Monday (2), Wednesday (4), Friday (6)
        self.preferredWorkoutDaysData = Self.encode([2, 4, 6])
    }

    // MARK: - Computed Accessors

    var experienceLevel: LiftingExperience {
        get { LiftingExperience(rawValue: experienceLevelRawValue) ?? .newLifter }
        set { experienceLevelRawValue = newValue.rawValue }
    }

    var nextWorkoutType: WorkoutType {
        get { WorkoutType(rawValue: nextWorkoutTypeRawValue) ?? .A }
        set { nextWorkoutTypeRawValue = newValue.rawValue }
    }

    var currentWeights: [String: Double] {
        get { Self.decode([String: Double].self, from: currentWeightsData) ?? [:] }
        set { currentWeightsData = Self.encode(newValue) }
    }

    var failureCounts: [String: Int] {
        get { Self.decode([String: Int].self, from: failureCountsData) ?? [:] }
        set { failureCountsData = Self.encode(newValue) }
    }

    var preferredWorkoutDays: [Int] {
        get { Self.decode([Int].self, from: preferredWorkoutDaysData) ?? [2, 4, 6] }
        set { preferredWorkoutDaysData = Self.encode(newValue) }
    }

    // MARK: - Private Helpers

    private static func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        guard !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

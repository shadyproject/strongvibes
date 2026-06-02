import Foundation
import SwiftData

/// A completed or in-progress workout session.
@Model
final class WorkoutRecord {

    // MARK: - Properties

    var id: UUID
    var date: Date
    /// Raw value of ``WorkoutType``.
    var typeRawValue: String
    var isCompleted: Bool
    var durationSeconds: Int?
    @Relationship(deleteRule: .cascade, inverse: \ExercisePerformance.workout)
    var performances: [ExercisePerformance]

    // MARK: - Initialization

    init(type: WorkoutType, date: Date = .now) {
        self.id = UUID()
        self.date = date
        self.typeRawValue = type.rawValue
        self.isCompleted = false
        self.performances = []
    }

    // MARK: - Computed

    var workoutType: WorkoutType {
        WorkoutType(rawValue: typeRawValue) ?? .A
    }

    var allExercisesCompleted: Bool {
        !performances.isEmpty && performances.allSatisfy(\.allSetsCompleted)
    }
}

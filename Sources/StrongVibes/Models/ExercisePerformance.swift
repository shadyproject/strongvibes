import Foundation
import SwiftData

/// The performance of one exercise within a ``WorkoutRecord``.
@Model
final class ExercisePerformance {

    // MARK: - Properties

    var exerciseName: String
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double
    /// Number of sets completed with the target reps.
    var completedSets: Int
    var workout: WorkoutRecord?

    // MARK: - Initialization

    init(
        exerciseName: String,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double
    ) {
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.completedSets = 0
    }

    // MARK: - Computed

    var allSetsCompleted: Bool { completedSets >= targetSets }

    var formattedWeight: String {
        targetWeight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(targetWeight)) lbs"
            : "\(targetWeight) lbs"
    }

    var setsDisplay: String { "\(targetSets)×\(targetReps)" }
}

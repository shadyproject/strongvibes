import Foundation
import SwiftData

/// The best weight lifted for an exercise at 5 reps.
@Model
final class PersonalRecord {

    // MARK: - Properties

    var exerciseName: String
    var weight: Double
    var reps: Int
    var achievedAt: Date

    // MARK: - Initialization

    init(exerciseName: String, weight: Double, reps: Int, achievedAt: Date = .now) {
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.achievedAt = achievedAt
    }

    // MARK: - Computed

    var formattedWeight: String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight)) lbs"
            : "\(weight) lbs"
    }
}

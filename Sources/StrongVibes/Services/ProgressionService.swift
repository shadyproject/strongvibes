import Foundation

/// Computes weight progressions and deloads based on workout performance.
struct ProgressionService: Sendable {

    // MARK: - Public Interface

    /// Applies the result of completed performances to the current weights and failure counts.
    ///
    /// - Returns: Updated weights and failure counts.
    func applyWorkout(
        performances: [PerformanceSummary],
        currentWeights: [String: Double],
        failureCounts: [String: Int],
        definitions: [ExerciseDefinition]
    ) -> (weights: [String: Double], failureCounts: [String: Int]) {
        var weights = currentWeights
        var failures = failureCounts

        for performance in performances {
            guard let definition = definitions.first(where: { $0.name == performance.exerciseName })
            else { continue }

            if performance.allSetsCompleted {
                let current = weights[performance.exerciseName] ?? performance.targetWeight
                weights[performance.exerciseName] = current + definition.weightIncrement
                failures[performance.exerciseName] = 0
            } else {
                let currentFailures = (failures[performance.exerciseName] ?? 0) + 1
                failures[performance.exerciseName] = currentFailures

                if currentFailures >= ProgramConstants.failuresBeforeDeload {
                    let current = weights[performance.exerciseName] ?? performance.targetWeight
                    let deloaded = ProgramConstants.roundToPlate(
                        current * ProgramConstants.deloadFactor
                    )
                    weights[performance.exerciseName] = max(deloaded, 45)
                    failures[performance.exerciseName] = 0
                }
            }
        }

        return (weights, failures)
    }

    /// Builds ``ExercisePerformance``-compatible summaries from the SwiftData models.
    struct PerformanceSummary: Sendable {
        let exerciseName: String
        let targetWeight: Double
        let targetSets: Int
        let completedSets: Int

        var allSetsCompleted: Bool { completedSets >= targetSets }
    }
}

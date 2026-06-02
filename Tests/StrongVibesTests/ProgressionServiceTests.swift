import Testing
import Foundation
@testable import StrongVibes

@Suite("ProgressionService")
struct ProgressionServiceTests {

    let service = ProgressionService()
    let definitions = ExerciseDefinition.all

    private func summary(
        name: String,
        weight: Double,
        totalSets: Int,
        completed: Int
    ) -> ProgressionService.PerformanceSummary {
        ProgressionService.PerformanceSummary(
            exerciseName: name,
            targetWeight: weight,
            targetSets: totalSets,
            completedSets: completed
        )
    }

    // MARK: - Successful Progression

    @Test("Adds increment to squat after all sets completed")
    func squatProgressesAfterSuccess() {
        let perf = summary(name: "Squat", weight: 135, totalSets: 5, completed: 5)
        let (weights, failures) = service.applyWorkout(
            performances: [perf],
            currentWeights: ["Squat": 135],
            failureCounts: [:],
            definitions: definitions
        )
        #expect(weights["Squat"] == 145)
        #expect(failures["Squat"] == 0)
    }

    @Test("Adds 5lb increment to bench press after success")
    func benchPressProgressesAfterSuccess() {
        let perf = summary(name: "Bench Press", weight: 95, totalSets: 5, completed: 5)
        let (weights, _) = service.applyWorkout(
            performances: [perf],
            currentWeights: ["Bench Press": 95],
            failureCounts: [:],
            definitions: definitions
        )
        #expect(weights["Bench Press"] == 100)
    }

    // MARK: - Failure Tracking

    @Test("Increments failure count on incomplete sets")
    func failureCountIncrementsOnMissedSets() {
        let perf = summary(name: "Squat", weight: 135, totalSets: 5, completed: 4)
        let (_, failures) = service.applyWorkout(
            performances: [perf],
            currentWeights: ["Squat": 135],
            failureCounts: [:],
            definitions: definitions
        )
        #expect(failures["Squat"] == 1)
    }

    @Test("Resets failure count after a successful session")
    func failureCountResetsAfterSuccess() {
        let perf = summary(name: "Squat", weight: 135, totalSets: 5, completed: 5)
        let (_, failures) = service.applyWorkout(
            performances: [perf],
            currentWeights: ["Squat": 135],
            failureCounts: ["Squat": 2],
            definitions: definitions
        )
        #expect(failures["Squat"] == 0)
    }

    // MARK: - Deload

    @Test("Triggers deload after 3 consecutive failures")
    func deloadAfterThreeFailures() {
        let perf = summary(name: "Squat", weight: 200, totalSets: 5, completed: 3)
        let (weights, failures) = service.applyWorkout(
            performances: [perf],
            currentWeights: ["Squat": 200],
            failureCounts: ["Squat": 2],
            definitions: definitions
        )
        // 200 * 0.9 = 180, rounded to nearest 2.5 = 180
        #expect(weights["Squat"] == 180)
        #expect(failures["Squat"] == 0)
    }

    @Test("Deload rounds to nearest 2.5lb plate increment")
    func deloadRoundsToNearestPlate() {
        let perf = summary(name: "Bench Press", weight: 105, totalSets: 5, completed: 2)
        let (weights, _) = service.applyWorkout(
            performances: [perf],
            currentWeights: ["Bench Press": 105],
            failureCounts: ["Bench Press": 2],
            definitions: definitions
        )
        // 105 * 0.9 = 94.5 → rounds to 95
        let result = weights["Bench Press"] ?? 0
        #expect(result == 95)
    }

    @Test("Deload never goes below bar weight (45 lbs)")
    func deloadFloorIsBarWeight() {
        let perf = summary(name: "Bench Press", weight: 45, totalSets: 5, completed: 0)
        let (weights, _) = service.applyWorkout(
            performances: [perf],
            currentWeights: ["Bench Press": 45],
            failureCounts: ["Bench Press": 2],
            definitions: definitions
        )
        #expect((weights["Bench Press"] ?? 0) >= 45)
    }

    // MARK: - ProgramConstants

    @Test("roundToPlate rounds to nearest 2.5", arguments: [
        (94.5, 95.0), (93.0, 92.5), (95.0, 95.0), (97.3, 97.5),
    ])
    func roundToPlate(input: Double, expected: Double) {
        #expect(ProgramConstants.roundToPlate(input) == expected)
    }

    // MARK: - WorkoutType

    @Test("WorkoutType alternates A→B→A")
    func workoutTypeAlternates() {
        #expect(WorkoutType.A.next == .B)
        #expect(WorkoutType.B.next == .A)
    }

    // MARK: - Program Templates

    @Test("Workout A contains squat, bench press, barbell row")
    func workoutAExercises() {
        let template = WorkoutTemplate.template(for: .A)
        let names = template.exercises.map(\.name)
        #expect(names.contains("Squat"))
        #expect(names.contains("Bench Press"))
        #expect(names.contains("Barbell Row"))
        #expect(names.count == 3)
    }

    @Test("Workout B contains squat, overhead press, deadlift")
    func workoutBExercises() {
        let template = WorkoutTemplate.template(for: .B)
        let names = template.exercises.map(\.name)
        #expect(names.contains("Squat"))
        #expect(names.contains("Overhead Press"))
        #expect(names.contains("Deadlift"))
        #expect(names.count == 3)
    }

    @Test("Deadlift is 1x5 not 5x5")
    func deadliftIsSingleSet() {
        #expect(ExerciseDefinition.deadlift.sets == 1)
        #expect(ExerciseDefinition.deadlift.reps == 5)
    }

    @Test("New lifter starting weights match expected values")
    func newLifterStartingWeights() {
        let weights = ProgramConstants.newLifterStartingWeights
        #expect(weights["Squat"] == 45)
        #expect(weights["Bench Press"] == 45)
        #expect(weights["Barbell Row"] == 65)
        #expect(weights["Overhead Press"] == 45)
        #expect(weights["Deadlift"] == 95)
    }
}

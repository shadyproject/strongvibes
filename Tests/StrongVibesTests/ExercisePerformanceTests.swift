import Testing
import Foundation
@testable import StrongVibes

@Suite("ExercisePerformance")
struct ExercisePerformanceTests {

    @Test("allSetsCompleted is true when completedSets equals targetSets")
    func allSetsCompletedWhenEqual() {
        let perf = ExercisePerformance(
            exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 135
        )
        perf.completedSets = 5
        #expect(perf.allSetsCompleted)
    }

    @Test("allSetsCompleted is false when completedSets is less than targetSets")
    func notAllSetsCompleted() {
        let perf = ExercisePerformance(
            exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 135
        )
        perf.completedSets = 4
        #expect(!perf.allSetsCompleted)
    }

    @Test("allSetsCompleted is true when completedSets exceeds targetSets")
    func overcompletion() {
        let perf = ExercisePerformance(
            exerciseName: "Deadlift", targetSets: 1, targetReps: 5, targetWeight: 225
        )
        perf.completedSets = 1
        #expect(perf.allSetsCompleted)
    }

    @Test("formattedWeight omits decimal for whole numbers")
    func formattedWeightWholeNumber() {
        let perf = ExercisePerformance(
            exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 135
        )
        #expect(perf.formattedWeight == "135 lbs")
    }

    @Test("formattedWeight includes decimal for fractional weights")
    func formattedWeightFractional() {
        let perf = ExercisePerformance(
            exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 132.5
        )
        #expect(perf.formattedWeight == "132.5 lbs")
    }

    @Test("setsDisplay formats as NxM")
    func setsDisplay() {
        let perf = ExercisePerformance(
            exerciseName: "Bench Press", targetSets: 5, targetReps: 5, targetWeight: 95
        )
        #expect(perf.setsDisplay == "5×5")
    }

    @Test("setsDisplay for deadlift shows 1x5")
    func setsDisplayDeadlift() {
        let perf = ExercisePerformance(
            exerciseName: "Deadlift", targetSets: 1, targetReps: 5, targetWeight: 225
        )
        #expect(perf.setsDisplay == "1×5")
    }
}

@Suite("WorkoutRecord")
struct WorkoutRecordTests {

    @Test("allExercisesCompleted is false when no performances exist")
    func noPerformances() {
        let workout = WorkoutRecord(type: .A)
        #expect(!workout.allExercisesCompleted)
    }

    @Test("workoutType returns the correct enum value")
    func workoutTypeEnum() {
        #expect(WorkoutRecord(type: .A).workoutType == .A)
        #expect(WorkoutRecord(type: .B).workoutType == .B)
    }

    @Test("allExercisesCompleted is true when all performances complete")
    func allComplete() {
        let workout = WorkoutRecord(type: .A)
        let p1 = ExercisePerformance(exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 135)
        p1.completedSets = 5
        let p2 = ExercisePerformance(exerciseName: "Bench Press", targetSets: 5, targetReps: 5, targetWeight: 95)
        p2.completedSets = 5
        workout.performances = [p1, p2]
        #expect(workout.allExercisesCompleted)
    }

    @Test("allExercisesCompleted is false when some performances are incomplete")
    func partiallyComplete() {
        let workout = WorkoutRecord(type: .A)
        let p1 = ExercisePerformance(exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 135)
        p1.completedSets = 5
        let p2 = ExercisePerformance(exerciseName: "Bench Press", targetSets: 5, targetReps: 5, targetWeight: 95)
        p2.completedSets = 3
        workout.performances = [p1, p2]
        #expect(!workout.allExercisesCompleted)
    }
}

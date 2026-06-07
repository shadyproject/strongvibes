import Foundation
import Observation
import SwiftData

/// Cancellable container for the rest timer task, safe to access from nonisolated deinit.
private final class RestTimerHandle: @unchecked Sendable {
    var task: Task<Void, Never>?
    func cancel() { task?.cancel(); task = nil }
}

/// Drives the active workout screen, managing per-set completion and the rest timer.
@Observable
@MainActor
final class ActiveWorkoutViewModel {

    // MARK: - Published State

    var workout: WorkoutRecord
    var currentExerciseIndex: Int = 0
    var currentSetIndex: Int = 0
    var restSecondsRemaining: Int = 0
    var isResting: Bool = false
    var isWorkoutComplete: Bool = false
    var startedAt: Date = .now

    // MARK: - Constants

    let defaultRestSeconds = 90

    // MARK: - Private

    // Wrapper so deinit (nonisolated in Swift 6) can cancel without crossing actor boundaries.
    private let timerHandle = RestTimerHandle()

    // Tracks when the current set window began (rest ended or workout started).
    private var currentSetStartDate: Date = .now

    // MARK: - Initialization

    init(workout: WorkoutRecord) {
        self.workout = workout
        let startDate = workout.date
        Task {
            await HealthKitService.shared.startWorkout(startDate: startDate)
        }
    }

    deinit {
        timerHandle.cancel()
        // Safety net: discard any open HK builder if finish/discard was not called explicitly.
        Task { await HealthKitService.shared.discardWorkout() }
    }

    // MARK: - Computed

    var currentPerformance: ExercisePerformance? {
        guard currentExerciseIndex < workout.performances.count else { return nil }
        return workout.performances[currentExerciseIndex]
    }

    var progress: Double {
        let total = workout.performances.reduce(0) { $0 + $1.targetSets }
        let done = workout.performances.reduce(0) { $0 + $1.completedSets }
        guard total > 0 else { return 0 }
        return Double(done) / Double(total)
    }

    // MARK: - Public Methods

    func completeSet() {
        guard let performance = currentPerformance else { return }

        // Capture timing before mutating state.
        let segmentStart = currentSetStartDate
        let segmentEnd = Date()
        let exerciseName = performance.exerciseName
        let weight = performance.targetWeight
        let reps = performance.targetReps

        performance.completedSets += 1

        Task {
            await HealthKitService.shared.addSegment(
                start: segmentStart,
                end: segmentEnd,
                exerciseName: exerciseName,
                weight: weight,
                reps: reps
            )
        }

        let allSetsForExerciseDone = performance.completedSets >= performance.targetSets
        if allSetsForExerciseDone {
            advanceToNextExercise()
        } else {
            startRestTimer()
        }
    }

    func skipRestTimer() {
        stopRestTimer()
        isResting = false
        currentSetStartDate = Date()
    }

    func addWeight(to performance: ExercisePerformance, amount: Double = 2.5) {
        performance.targetWeight = max(0, performance.targetWeight + amount)
    }

    func subtractWeight(from performance: ExercisePerformance, amount: Double = 2.5) {
        performance.targetWeight = max(0, performance.targetWeight - amount)
    }

    // MARK: - HealthKit Lifecycle

    /// Saves the completed workout to HealthKit. Call before dismissing the view on success.
    func finishHealthKitWorkout() async {
        await HealthKitService.shared.finishWorkout(endDate: Date())
    }

    /// Discards the in-progress HealthKit workout without saving. Call on cancellation.
    func discardHealthKitWorkout() async {
        await HealthKitService.shared.discardWorkout()
    }

    // MARK: - Private

    private func advanceToNextExercise() {
        stopRestTimer()
        isResting = false

        let nextIndex = currentExerciseIndex + 1
        if nextIndex < workout.performances.count {
            currentExerciseIndex = nextIndex
            currentSetIndex = 0
            currentSetStartDate = Date()
        } else {
            workout.durationSeconds = Int(Date.now.timeIntervalSince(startedAt))
            isWorkoutComplete = true
        }
    }

    private func startRestTimer() {
        isResting = true
        restSecondsRemaining = defaultRestSeconds
        stopRestTimer()

        timerHandle.task = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self, self.isResting else { return }
                    if self.restSecondsRemaining > 0 {
                        self.restSecondsRemaining -= 1
                    } else {
                        self.stopRestTimer()
                        self.isResting = false
                        self.currentSetStartDate = Date()
                    }
                }
            }
        }
    }

    private func stopRestTimer() {
        timerHandle.cancel()
    }
}

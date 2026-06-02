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

    // MARK: - Initialization

    init(workout: WorkoutRecord) {
        self.workout = workout
    }

    deinit {
        timerHandle.cancel()
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
        performance.completedSets += 1

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
    }

    func addWeight(to performance: ExercisePerformance, amount: Double = 2.5) {
        performance.targetWeight = max(0, performance.targetWeight + amount)
    }

    func subtractWeight(from performance: ExercisePerformance, amount: Double = 2.5) {
        performance.targetWeight = max(0, performance.targetWeight - amount)
    }

    // MARK: - Private

    private func advanceToNextExercise() {
        stopRestTimer()
        isResting = false

        let nextIndex = currentExerciseIndex + 1
        if nextIndex < workout.performances.count {
            currentExerciseIndex = nextIndex
            currentSetIndex = 0
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
                    }
                }
            }
        }
    }

    private func stopRestTimer() {
        timerHandle.cancel()
    }
}

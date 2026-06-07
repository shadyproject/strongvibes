import Foundation
import SwiftData
import Observation

/// Drives the home dashboard and coordinates workout start/completion.
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Published State

    var userProfile: UserProfile?
    var nextWorkoutDate: Date?
    var isWorkoutDueToday: Bool = false
    var activeWorkout: WorkoutRecord?

    // MARK: - Private

    private let scheduler = WorkoutScheduler()
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        #if DEBUG
        observeDevMenuChanges()
        #endif
    }

    // MARK: - Debug

    #if DEBUG
    /// Reloads profile state whenever the developer menu mutates the data store.
    private func observeDevMenuChanges() {
        Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .devMenuDidChange) {
                self?.loadProfile()
            }
        }
    }
    #endif

    // MARK: - Public Methods

    func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try? modelContext.fetch(descriptor)
        let profile = profiles?.first ?? createDefaultProfile()
        userProfile = profile
        refreshSchedule(for: profile)
    }

    func startWorkout() -> WorkoutRecord? {
        guard let profile = userProfile else { return nil }
        let type = profile.nextWorkoutType
        let template = WorkoutTemplate.template(for: type)
        let workout = WorkoutRecord(type: type)

        for definition in template.exercises {
            let weight = profile.currentWeights[definition.name]
                ?? ProgramConstants.newLifterStartingWeights[definition.name]
                ?? 45
            let performance = ExercisePerformance(
                exerciseName: definition.name,
                targetSets: definition.sets,
                targetReps: definition.reps,
                targetWeight: weight
            )
            performance.workout = workout
            workout.performances.append(performance)
        }

        modelContext.insert(workout)
        activeWorkout = workout
        return workout
    }

    func completeWorkout(_ workout: WorkoutRecord) {
        guard let profile = userProfile else { return }
        workout.isCompleted = true

        let template = WorkoutTemplate.template(for: workout.workoutType)
        let summaries = workout.performances.map { performance in
            ProgressionService.PerformanceSummary(
                exerciseName: performance.exerciseName,
                targetWeight: performance.targetWeight,
                targetSets: performance.targetSets,
                completedSets: performance.completedSets
            )
        }

        let progression = ProgressionService()
        let (newWeights, newFailures) = progression.applyWorkout(
            performances: summaries,
            currentWeights: profile.currentWeights,
            failureCounts: profile.failureCounts,
            definitions: template.exercises
        )

        profile.currentWeights = newWeights
        profile.failureCounts = newFailures
        profile.lastWorkoutDate = workout.date
        profile.nextWorkoutType = profile.nextWorkoutType.next

        checkAndRecordPRs(for: workout)
        refreshSchedule(for: profile)
        scheduleNextNotification(for: profile)

        activeWorkout = nil
        try? modelContext.save()
    }

    func cancelWorkout(_ workout: WorkoutRecord) {
        modelContext.delete(workout)
        activeWorkout = nil
        try? modelContext.save()
    }

    // MARK: - Private

    private func createDefaultProfile() -> UserProfile {
        let profile = UserProfile()
        modelContext.insert(profile)
        return profile
    }

    private func refreshSchedule(for profile: UserProfile) {
        let date = scheduler.nextWorkoutDate(
            after: profile.lastWorkoutDate,
            preferredDays: profile.preferredWorkoutDays,
            hour: profile.notificationHour,
            minute: profile.notificationMinute
        )
        profile.nextWorkoutDate = date
        nextWorkoutDate = date
        isWorkoutDueToday = scheduler.isWorkoutDueToday(nextWorkoutDate: date)
    }

    private func scheduleNextNotification(for profile: UserProfile) {
        guard let date = profile.nextWorkoutDate else { return }
        Task {
            let status = await NotificationService.shared.authorizationStatus()
            guard status == .authorized else { return }
            await NotificationService.shared.scheduleWorkoutReminder(
                for: date,
                workoutType: profile.nextWorkoutType
            )
        }
    }

    private func checkAndRecordPRs(for workout: WorkoutRecord) {
        let prDescriptor = FetchDescriptor<PersonalRecord>()
        let existingPRs = (try? modelContext.fetch(prDescriptor)) ?? []

        for performance in workout.performances where performance.allSetsCompleted {
            let currentBest = existingPRs
                .filter { $0.exerciseName == performance.exerciseName }
                .max(by: { $0.weight < $1.weight })

            if currentBest == nil || performance.targetWeight > (currentBest?.weight ?? 0) {
                let pr = PersonalRecord(
                    exerciseName: performance.exerciseName,
                    weight: performance.targetWeight,
                    reps: performance.targetReps,
                    achievedAt: workout.date
                )
                modelContext.insert(pr)
            }
        }
    }
}

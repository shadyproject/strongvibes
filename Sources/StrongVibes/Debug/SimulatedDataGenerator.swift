#if DEBUG
import Foundation
import SwiftData

/// Generates realistic-looking SL5x5 workout history for development and testing.
struct SimulatedDataGenerator {

    // MARK: - Period

    enum Period: String, CaseIterable {
        case day = "1 Day"
        case week = "1 Week"
        case month = "1 Month"

        /// Number of workout sessions to generate.
        var sessionCount: Int {
            switch self {
            case .day: return 1
            case .week: return 3
            case .month: return 13
            }
        }
    }

    // MARK: - Public

    /// Generates simulated workouts for the given period and inserts them into `context`.
    ///
    /// Existing workout history is preserved; new sessions are inserted before existing ones.
    func generate(period: Period, in context: ModelContext) throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var weights = ProgramConstants.newLifterStartingWeights
        var workoutType = WorkoutType.A
        let dates = makeDates(count: period.sessionCount, endingOn: today, calendar: calendar)

        for date in dates {
            let workout = WorkoutRecord(type: workoutType, date: date)
            workout.isCompleted = true
            workout.durationSeconds = Int.random(in: 2400...3600)

            let template = WorkoutTemplate.template(for: workoutType)
            for exercise in template.exercises {
                let weight = weights[exercise.name] ?? 45
                let performance = ExercisePerformance(
                    exerciseName: exercise.name,
                    targetSets: exercise.sets,
                    targetReps: exercise.reps,
                    targetWeight: weight
                )
                // All sets successful — no failures in simulated data.
                performance.completedSets = exercise.sets
                performance.workout = workout
                workout.performances.append(performance)

                updatePR(exerciseName: exercise.name, weight: weight, reps: exercise.reps, date: date, in: context)
                weights[exercise.name] = weight + exercise.weightIncrement
            }

            context.insert(workout)
            workoutType = workoutType.next
        }

        updateProfile(
            lastWorkoutDate: dates.last,
            nextType: workoutType,
            weights: weights,
            in: context
        )

        try context.save()
        NotificationCenter.default.post(name: .devMenuDidChange, object: nil)
    }

    // MARK: - Private

    /// Produces `count` dates spaced ~2 days apart, ending on `today`.
    private func makeDates(count: Int, endingOn today: Date, calendar: Calendar) -> [Date] {
        var result: [Date] = []
        var cursor = today
        for _ in 0..<count {
            result.append(cursor)
            cursor = calendar.date(byAdding: .day, value: -2, to: cursor) ?? cursor
        }
        return result.reversed()
    }

    private func updatePR(
        exerciseName: String,
        weight: Double,
        reps: Int,
        date: Date,
        in context: ModelContext
    ) {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.exerciseName == exerciseName }
        )
        let best = (try? context.fetch(descriptor))?.max(by: { $0.weight < $1.weight })
        guard best == nil || weight > (best?.weight ?? 0) else { return }
        context.insert(PersonalRecord(exerciseName: exerciseName, weight: weight, reps: reps, achievedAt: date))
    }

    private func updateProfile(
        lastWorkoutDate: Date?,
        nextType: WorkoutType,
        weights: [String: Double],
        in context: ModelContext
    ) {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? context.fetch(descriptor))?.first else { return }
        profile.lastWorkoutDate = lastWorkoutDate
        profile.nextWorkoutType = nextType
        profile.currentWeights = weights
        profile.nextWorkoutDate = WorkoutScheduler().nextWorkoutDate(
            after: lastWorkoutDate,
            preferredDays: profile.preferredWorkoutDays,
            hour: profile.notificationHour,
            minute: profile.notificationMinute
        )
    }
}
#endif

import Foundation
import HealthKit

/// Manages HealthKit workout recording for strength training sessions.
///
/// All operations are best-effort: failures are not surfaced to the UI.
/// Use `HealthKitService.shared` from any context; the actor serialises access.
actor HealthKitService {

    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private var builder: HKWorkoutBuilder?

    // MARK: - Availability

    /// True when HealthKit is supported on this device.
    nonisolated var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization

    /// Requests write access to workouts.
    ///
    /// - Returns: `true` if the user granted access.
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await healthStore.requestAuthorization(
                toShare: [HKObjectType.workoutType()],
                read: []
            )
        } catch {
            return false
        }
        return healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    /// The current HealthKit authorisation status for writing workouts.
    func authorizationStatus() -> HKAuthorizationStatus {
        guard isAvailable else { return .notDetermined }
        return healthStore.authorizationStatus(for: HKObjectType.workoutType())
    }

    // MARK: - Workout Lifecycle

    /// Begins a new traditional strength training workout session.
    ///
    /// Does nothing if HealthKit is unavailable or the user has not granted access.
    ///
    /// - Parameter startDate: The date the workout began.
    func startWorkout(startDate: Date) async {
        guard isAvailable, authorizationStatus() == .sharingAuthorized else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let newBuilder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: config,
            device: .local()
        )
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                newBuilder.beginCollection(withStart: startDate) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            builder = newBuilder
        } catch {
            // Non-fatal: app continues without HealthKit recording.
        }
    }

    /// Records a completed set as a segment event within the active workout.
    ///
    /// - Parameters:
    ///   - start: When the set began (rest timer ended or workout started).
    ///   - end: When the user tapped "Complete Set".
    ///   - exerciseName: Name of the exercise, stored in event metadata.
    ///   - weight: Target weight in lbs, stored in event metadata.
    ///   - reps: Target reps, stored in event metadata.
    func addSegment(
        start: Date,
        end: Date,
        exerciseName: String,
        weight: Double,
        reps: Int
    ) async {
        guard let builder else { return }

        // DateInterval requires end > start.
        let safeEnd = end > start ? end : start.addingTimeInterval(1)
        let event = HKWorkoutEvent(
            type: .segment,
            dateInterval: DateInterval(start: start, end: safeEnd),
            metadata: [
                HKMetadataKeyWorkoutBrandName: "StrongVibes",
                "exerciseName": exerciseName,
                "targetWeightLbs": weight,
                "targetReps": reps,
            ]
        )
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.addWorkoutEvents([event]) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            // Non-fatal.
        }
    }

    /// Ends collection and persists the workout to HealthKit.
    ///
    /// - Parameter endDate: The date the workout finished.
    func finishWorkout(endDate: Date) async {
        guard let current = builder else { return }
        builder = nil
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                current.endCollection(withEnd: endDate) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                current.finishWorkout { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            // Non-fatal.
        }
    }

    /// Discards the in-progress workout without saving to HealthKit.
    func discardWorkout() async {
        guard let current = builder else { return }
        builder = nil
        current.discardWorkout()
    }
}

import Foundation

// MARK: - Experience Level

enum LiftingExperience: String, Codable, Sendable, CaseIterable {
    case newLifter
    case experiencedLifter

    var displayName: String {
        switch self {
        case .newLifter: return String(localized: "New Lifter")
        case .experiencedLifter: return String(localized: "Experienced Lifter")
        }
    }
}

// MARK: - Workout Type

enum WorkoutType: String, Codable, Sendable, CaseIterable {
    case A
    case B

    var next: WorkoutType {
        switch self {
        case .A: return .B
        case .B: return .A
        }
    }

    var displayName: String { "Workout \(rawValue)" }
}

// MARK: - Exercise Definition

struct ExerciseDefinition: Sendable, Hashable, Identifiable {
    let name: String
    let sets: Int
    let reps: Int
    /// Weight added per successful session, in pounds.
    let weightIncrement: Double

    var id: String { name }

    static let squat = ExerciseDefinition(
        name: "Squat", sets: 5, reps: 5, weightIncrement: 10
    )
    static let benchPress = ExerciseDefinition(
        name: "Bench Press", sets: 5, reps: 5, weightIncrement: 5
    )
    static let barbellRow = ExerciseDefinition(
        name: "Barbell Row", sets: 5, reps: 5, weightIncrement: 5
    )
    static let overheadPress = ExerciseDefinition(
        name: "Overhead Press", sets: 5, reps: 5, weightIncrement: 5
    )
    static let deadlift = ExerciseDefinition(
        name: "Deadlift", sets: 1, reps: 5, weightIncrement: 10
    )

    static let all: [ExerciseDefinition] = [
        .squat, .benchPress, .barbellRow, .overheadPress, .deadlift,
    ]
}

// MARK: - Workout Template

struct WorkoutTemplate: Sendable {
    let type: WorkoutType
    let exercises: [ExerciseDefinition]

    static let workoutA = WorkoutTemplate(
        type: .A,
        exercises: [.squat, .benchPress, .barbellRow]
    )

    static let workoutB = WorkoutTemplate(
        type: .B,
        exercises: [.squat, .overheadPress, .deadlift]
    )

    static func template(for type: WorkoutType) -> WorkoutTemplate {
        switch type {
        case .A: return .workoutA
        case .B: return .workoutB
        }
    }
}

// MARK: - Program Constants

enum ProgramConstants {
    /// Default starting weights (lbs) for new lifters.
    static let newLifterStartingWeights: [String: Double] = [
        "Squat": 45,
        "Bench Press": 45,
        "Barbell Row": 65,
        "Overhead Press": 45,
        "Deadlift": 95,
    ]

    /// Number of consecutive failures before a deload is triggered.
    static let failuresBeforeDeload = 3

    /// Fraction of current weight applied during a deload.
    static let deloadFactor = 0.9

    /// Smallest weight increment available (one 1.25lb plate per side).
    static let minimumPlateIncrement = 2.5

    static func roundToPlate(_ weight: Double) -> Double {
        (weight / minimumPlateIncrement).rounded() * minimumPlateIncrement
    }
}

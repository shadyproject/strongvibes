# StrongVibes

An iPhone app for running the [StrongLifts 5x5](https://stronglifts.com/5x5/) barbell program. Tracks workouts, manages progression, schedules sessions, and records personal bests.

## Features

- **Workout tracking** — Workout A (Squat / Bench Press / Barbell Row) and Workout B (Squat / Overhead Press / Deadlift), alternating each session
- **Automatic progression** — adds weight on success; deloads 10% after three consecutive failures on the same lift
- **Smart scheduling** — picks the next session date based on preferred training days (default Mon / Wed / Fri), enforcing at least one rest day between sessions
- **Local notifications** — reminds when a workout is due, scheduled to preferred time-of-day
- **Onboarding** — new lifter or experienced lifter paths, with custom starting weights for experienced lifters
- **Calendar history** — month grid showing completed Workout A / B sessions; tap any day to see the full session detail
- **Trends** — per-exercise weight-over-time chart with a drag-to-inspect detail card and summary stats
- **Personal records** — automatically recorded whenever a lift surpasses the previous best

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 16+ |
| iOS deployment target | 17.0 |
| Swift | 6.0 |
| XcodeGen | 2.x (`brew install xcodegen`) |

iPhone only. iPad and Mac Catalyst are not supported.

## Building

```bash
# 1. Generate the Xcode project from project.yml
xcodegen generate

# 2. Open in Xcode
open StrongVibes.xcodeproj

# 3. Select an iPhone simulator or device, then Build & Run (Cmd+R)
```

The `.xcodeproj` file is git-ignored; always regenerate it with `xcodegen generate` after pulling changes to `project.yml`.

## Running tests

```bash
xcodegen generate
xcodebuild test \
  -scheme StrongVibes \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Tests use the [Swift Testing](https://developer.apple.com/xcode/swift-testing/) framework. Three suites cover the core logic:

- `WorkoutSchedulerTests` — next-session date calculation and rest-day enforcement
- `ProgressionServiceTests` — weight increment, failure tracking, and deload logic
- `ExercisePerformanceTests` — model computed properties and workout completion state

## Project structure

```
Sources/StrongVibes/
├── App.swift                   # @main entry point
├── Models/                     # SwiftData @Model types
│   ├── LiftingProgram.swift    # Value types: exercises, templates, constants
│   ├── WorkoutRecord.swift
│   ├── ExercisePerformance.swift
│   ├── PersonalRecord.swift
│   └── UserProfile.swift
├── Services/
│   ├── ProgressionService.swift
│   ├── WorkoutScheduler.swift
│   └── NotificationService.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   └── ActiveWorkoutViewModel.swift
├── Views/
│   ├── Home/
│   ├── ActiveWorkout/
│   ├── History/
│   ├── Trends/
│   └── Onboarding/
├── Resources/
│   ├── Assets.xcassets/
│   └── Info.plist
└── Debug/                      # Compiled only in DEBUG builds
    ├── DevMenuView.swift       # Shake-activated developer menu
    ├── ShakeDetector.swift
    ├── SimulatedDataGenerator.swift
    └── DebugNotifications.swift

Tests/StrongVibesTests/
```

## Tech stack

- **SwiftUI** with the `@Observable` macro (Observation framework)
- **SwiftData** for persistence
- **Swift Concurrency** (`async/await`, `@MainActor`, `Actor`) throughout
- **Swift Charts** for the Trends view
- **Swift Testing** for unit tests
- **XcodeGen** for project generation (`project.yml` is the source of truth)
- Strict concurrency checking enabled; warnings treated as errors

## License

MIT

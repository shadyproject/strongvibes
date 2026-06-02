import SwiftUI
import SwiftData

struct OnboardingView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var step: OnboardingStep = .welcome
    @State private var selectedExperience: LiftingExperience = .newLifter
    @State private var startingWeights: [String: Double] = ProgramConstants.newLifterStartingWeights
    @State private var preferredDays: Set<Int> = [2, 4, 6]
    @State private var notificationTime: Date = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: .now
    ) ?? .now

    private enum OnboardingStep {
        case welcome, experience, weights, schedule, notifications
    }

    var body: some View {
        NavigationStack {
            VStack {
                switch step {
                case .welcome:
                    WelcomeStep(onNext: { step = .experience })
                case .experience:
                    ExperienceStep(
                        selected: $selectedExperience,
                        onNext: {
                            if selectedExperience == .newLifter {
                                startingWeights = ProgramConstants.newLifterStartingWeights
                                step = .schedule
                            } else {
                                step = .weights
                            }
                        }
                    )
                case .weights:
                    StartingWeightsStep(
                        weights: $startingWeights,
                        onNext: { step = .schedule }
                    )
                case .schedule:
                    ScheduleStep(
                        preferredDays: $preferredDays,
                        notificationTime: $notificationTime,
                        onNext: { step = .notifications }
                    )
                case .notifications:
                    NotificationsStep(onFinish: completeOnboarding)
                }
            }
            .animation(.easeInOut, value: step)
        }
    }

    private func completeOnboarding() {
        let profile = UserProfile()
        profile.experienceLevel = selectedExperience
        profile.currentWeights = startingWeights
        profile.preferredWorkoutDays = Array(preferredDays).sorted()
        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        profile.notificationHour = components.hour ?? 9
        profile.notificationMinute = components.minute ?? 0
        profile.onboardingCompleted = true
        profile.nextWorkoutType = .A
        modelContext.insert(profile)
        try? modelContext.save()
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {

    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            VStack(spacing: 12) {
                Text(String(localized: "StrongVibes"))
                    .font(.largeTitle)
                    .fontWeight(.black)
                Text(String(localized: "The StrongLifts 5×5 program.\nSimple. Progressive. Effective."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            OnboardingButton(title: String(localized: "Get Started"), action: onNext)
        }
        .padding()
    }
}

// MARK: - Experience

private struct ExperienceStep: View {

    @Binding var selected: LiftingExperience
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text(String(localized: "Your Experience"))
                    .font(.title)
                    .fontWeight(.bold)
                Text(String(localized: "This determines your starting weights."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                ExperienceCard(
                    experience: .newLifter,
                    description: String(localized: "Start with the bar. Build strength safely with progressive overload."),
                    isSelected: selected == .newLifter,
                    onTap: { selected = .newLifter }
                )
                ExperienceCard(
                    experience: .experiencedLifter,
                    description: String(localized: "Enter your current working weights and pick up where you left off."),
                    isSelected: selected == .experiencedLifter,
                    onTap: { selected = .experiencedLifter }
                )
            }

            Spacer()
            OnboardingButton(title: String(localized: "Continue"), action: onNext)
        }
        .padding()
    }
}

private struct ExperienceCard: View {

    let experience: LiftingExperience
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(experience.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding()
            .background(
                isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .accessibilityLabel("\(experience.displayName): \(description)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Starting Weights

private struct StartingWeightsStep: View {

    @Binding var weights: [String: Double]
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(String(localized: "Starting Weights"))
                    .font(.title)
                    .fontWeight(.bold)
                Text(String(localized: "Enter your current 5-rep working weight for each lift."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(ExerciseDefinition.all) { exercise in
                    WeightInputRow(
                        exerciseName: exercise.name,
                        weight: Binding(
                            get: { weights[exercise.name] ?? 45 },
                            set: { weights[exercise.name] = $0 }
                        )
                    )
                }
            }

            Spacer()
            OnboardingButton(title: String(localized: "Continue"), action: onNext)
        }
        .padding()
    }
}

private struct WeightInputRow: View {

    let exerciseName: String
    @Binding var weight: Double
    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(exerciseName)
                .font(.body)
            Spacer()
            HStack(spacing: 8) {
                Button {
                    weight = max(0, weight - 5)
                    text = formattedWeight(weight)
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                }
                .accessibilityLabel(String(localized: "Decrease \(exerciseName) weight"))

                TextField("lbs", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: text) {
                        if let value = Double(text) {
                            weight = value
                        }
                    }

                Button {
                    weight += 5
                    text = formattedWeight(weight)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
                .accessibilityLabel(String(localized: "Increase \(exerciseName) weight"))
            }
        }
        .onAppear { text = formattedWeight(weight) }
        .onChange(of: weight) { text = formattedWeight(weight) }
    }

    private func formattedWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}

// MARK: - Schedule

private struct ScheduleStep: View {

    @Binding var preferredDays: Set<Int>
    @Binding var notificationTime: Date
    let onNext: () -> Void

    private let weekdays: [(name: String, value: Int)] = [
        ("Sun", 1), ("Mon", 2), ("Tue", 3), ("Wed", 4),
        ("Thu", 5), ("Fri", 6), ("Sat", 7),
    ]

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text(String(localized: "Your Schedule"))
                    .font(.title)
                    .fontWeight(.bold)
                Text(String(localized: "Pick your workout days and reminder time."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "Workout Days"))
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(weekdays, id: \.value) { day in
                        let isSelected = preferredDays.contains(day.value)
                        Button {
                            if isSelected { preferredDays.remove(day.value) }
                            else { preferredDays.insert(day.value) }
                        } label: {
                            Text(day.name)
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .regular)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityLabel("\(day.name), \(isSelected ? "selected" : "not selected")")
                    }
                }
            }

            DatePicker(
                String(localized: "Reminder Time"),
                selection: $notificationTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)

            Spacer()
            OnboardingButton(title: String(localized: "Continue"), action: onNext)
        }
        .padding()
    }
}

// MARK: - Notifications

private struct NotificationsStep: View {

    let onFinish: () -> Void
    @State private var permissionRequested = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            VStack(spacing: 12) {
                Text(String(localized: "Stay Consistent"))
                    .font(.title)
                    .fontWeight(.bold)
                Text(String(localized: "Get a reminder when it's time to lift. Consistency beats intensity."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            VStack(spacing: 12) {
                OnboardingButton(title: String(localized: "Enable Notifications")) {
                    Task {
                        _ = await NotificationService.shared.requestAuthorization()
                        permissionRequested = true
                        onFinish()
                    }
                }
                Button(String(localized: "Skip for now")) {
                    onFinish()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Shared Button

private struct OnboardingButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [
            WorkoutRecord.self,
            ExercisePerformance.self,
            PersonalRecord.self,
            UserProfile.self,
        ], inMemory: true)
}

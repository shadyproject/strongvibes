import SwiftUI

struct ActiveWorkoutView: View {

    @State var viewModel: ActiveWorkoutViewModel
    let onComplete: () -> Void
    let onCancel: () -> Void
    @State private var showingCancelConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isWorkoutComplete {
                    workoutCompleteView
                } else {
                    workoutInProgressView
                }
            }
            .navigationTitle(viewModel.workout.workoutType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        showingCancelConfirmation = true
                    }
                }
            }
            .confirmationDialog(
                String(localized: "Cancel Workout"),
                isPresented: $showingCancelConfirmation
            ) {
                Button(String(localized: "Cancel Workout"), role: .destructive) {
                    onCancel()
                }
                Button(String(localized: "Keep Going"), role: .cancel) {}
            } message: {
                Text(String(localized: "This workout will not be saved."))
            }
        }
    }

    // MARK: - Subviews

    private var workoutInProgressView: some View {
        VStack(spacing: 0) {
            ProgressView(value: viewModel.progress)
                .padding(.horizontal)
                .padding(.bottom, 8)

            if viewModel.isResting {
                restTimerView
            }

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(viewModel.workout.performances.enumerated()), id: \.offset) { index, performance in
                        ExerciseSetView(
                            performance: performance,
                            isCurrent: index == viewModel.currentExerciseIndex,
                            isCompleted: index < viewModel.currentExerciseIndex,
                            onSetComplete: {
                                if index == viewModel.currentExerciseIndex {
                                    viewModel.completeSet()
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }

    private var restTimerView: some View {
        HStack {
            Image(systemName: "timer")
            Text(String(localized: "Rest: \(viewModel.restSecondsRemaining)s"))
                .fontWeight(.semibold)
            Spacer()
            Button(String(localized: "Skip")) {
                viewModel.skipRestTimer()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.1))
    }

    private var workoutCompleteView: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text(String(localized: "Workout Complete"))
                    .font(.title)
                    .fontWeight(.bold)
                if let seconds = viewModel.workout.durationSeconds {
                    Text(String(localized: "Duration: \(formatDuration(seconds))"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.workout.performances, id: \.exerciseName) { performance in
                    HStack {
                        Image(systemName: performance.allSetsCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(performance.allSetsCompleted ? .green : .red)
                        Text(performance.exerciseName)
                        Spacer()
                        Text("\(performance.completedSets)/\(performance.targetSets) sets")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Button {
                onComplete()
            } label: {
                Text(String(localized: "Finish"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    let workout = WorkoutRecord(type: .A)
    let p1 = ExercisePerformance(exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 135)
    let p2 = ExercisePerformance(exerciseName: "Bench Press", targetSets: 5, targetReps: 5, targetWeight: 95)
    workout.performances = [p1, p2]

    return ActiveWorkoutView(
        viewModel: ActiveWorkoutViewModel(workout: workout),
        onComplete: {},
        onCancel: {}
    )
}

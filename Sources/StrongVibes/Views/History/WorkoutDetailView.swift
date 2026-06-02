import SwiftUI
import SwiftData

struct WorkoutDetailView: View {

    let workout: WorkoutRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "Overview")) {
                    LabeledContent(
                        String(localized: "Date"),
                        value: workout.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
                    )
                    if let seconds = workout.durationSeconds {
                        LabeledContent(
                            String(localized: "Duration"),
                            value: formatDuration(seconds)
                        )
                    }
                    LabeledContent(
                        String(localized: "Exercises Completed"),
                        value: "\(workout.performances.filter(\.allSetsCompleted).count) / \(workout.performances.count)"
                    )
                }

                Section(String(localized: "Exercises")) {
                    ForEach(workout.performances, id: \.exerciseName) { performance in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(performance.exerciseName)
                                    .font(.headline)
                                Text("\(performance.setsDisplay) @ \(performance.formattedWeight)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                ForEach(0..<performance.targetSets, id: \.self) { index in
                                    Circle()
                                        .fill(index < performance.completedSets
                                              ? Color.green
                                              : Color.secondary.opacity(0.3))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(workout.workoutType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
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
    workout.isCompleted = true
    workout.durationSeconds = 2700
    let p = ExercisePerformance(exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 135)
    p.completedSets = 5
    workout.performances = [p]
    return WorkoutDetailView(workout: workout)
}

import SwiftUI
import SwiftData

struct HistoryView: View {

    @Query(sort: \WorkoutRecord.date, order: .reverse)
    private var workouts: [WorkoutRecord]
    @State private var selectedWorkout: WorkoutRecord?

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .navigationTitle(String(localized: "History"))
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }

    private var workoutList: some View {
        List {
            ForEach(workouts.filter(\.isCompleted)) { workout in
                Button {
                    selectedWorkout = workout
                } label: {
                    WorkoutRowView(workout: workout)
                }
                .foregroundStyle(.primary)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(String(localized: "No workouts yet"))
                .font(.title3)
                .fontWeight(.semibold)
            Text(String(localized: "Complete your first workout to see it here."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Row

private struct WorkoutRowView: View {

    let workout: WorkoutRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType.displayName)
                    .font(.headline)
                Text(workout.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                let completed = workout.performances.filter(\.allSetsCompleted).count
                let total = workout.performances.count
                Text("\(completed)/\(total) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let seconds = workout.durationSeconds {
                    let minutes = seconds / 60
                    Text("\(minutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [
            WorkoutRecord.self,
            ExercisePerformance.self,
        ], inMemory: true)
}

import SwiftUI
import SwiftData

struct PersonalRecordsView: View {

    @Query(sort: \PersonalRecord.achievedAt, order: .reverse)
    private var allRecords: [PersonalRecord]

    var body: some View {
        NavigationStack {
            Group {
                if allRecords.isEmpty {
                    emptyState
                } else {
                    recordsList
                }
            }
            .navigationTitle(String(localized: "Personal Records"))
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    private var recordsList: some View {
        List {
            ForEach(ExerciseDefinition.all) { exercise in
                if let pr = bestRecord(for: exercise.name) {
                    Section(exercise.name) {
                        PRRowView(record: pr)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(String(localized: "No records yet"))
                .font(.title3)
                .fontWeight(.semibold)
            Text(String(localized: "Complete workouts to set personal records."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func bestRecord(for exerciseName: String) -> PersonalRecord? {
        allRecords
            .filter { $0.exerciseName == exerciseName }
            .max(by: { $0.weight < $1.weight })
    }
}

// MARK: - PR Row

private struct PRRowView: View {

    let record: PersonalRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.formattedWeight)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(record.reps) reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text(record.achievedAt.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PersonalRecordsView()
        .modelContainer(for: PersonalRecord.self, inMemory: true)
}

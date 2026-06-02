import SwiftUI
import SwiftData

struct DashboardView: View {

    var viewModel: HomeViewModel
    @Binding var showingActiveWorkout: Bool
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    nextWorkoutCard
                    currentWeightsCard
                }
                .padding()
            }
            .navigationTitle(String(localized: "StrongVibes"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel(String(localized: "Settings"))
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(profile: viewModel.userProfile)
                    .onDisappear { viewModel.loadProfile() }
            }
        }
    }

    // MARK: - Subviews

    private var nextWorkoutCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userProfile?.nextWorkoutType.displayName ?? "Workout A")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(workoutDateLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                workoutStatusBadge
            }

            if viewModel.isWorkoutDueToday {
                Button {
                    if let workout = viewModel.startWorkout() {
                        _ = workout
                        showingActiveWorkout = true
                    }
                } label: {
                    Text(String(localized: "Start Workout"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel(String(localized: "Start today's workout"))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var workoutDateLabel: String {
        guard let date = viewModel.nextWorkoutDate else { return String(localized: "Not scheduled") }
        if Calendar.current.isDateInToday(date) {
            return String(localized: "Today")
        }
        if Calendar.current.isDateInTomorrow(date) {
            return String(localized: "Tomorrow")
        }
        return date.formatted(.dateTime.weekday(.wide).month().day())
    }

    private var workoutStatusBadge: some View {
        let isToday = viewModel.isWorkoutDueToday
        return Text(isToday ? String(localized: "Due Today") : String(localized: "Upcoming"))
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isToday ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.15))
            .foregroundStyle(isToday ? Color.accentColor : Color.secondary)
            .clipShape(Capsule())
    }

    private var currentWeightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Current Working Weights"))
                .font(.headline)

            let weights = viewModel.userProfile?.currentWeights ?? [:]
            let exercises = ExerciseDefinition.all
            ForEach(exercises) { exercise in
                HStack {
                    Text(exercise.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(formattedWeight(weights[exercise.name] ?? 0))
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func formattedWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight)) lbs"
            : "\(weight) lbs"
    }
}

#Preview {
    let profile = UserProfile()
    profile.onboardingCompleted = true
    return DashboardView(
        viewModel: HomeViewModel(modelContext: ModelContext(try! ModelContainer(for: UserProfile.self))),
        showingActiveWorkout: .constant(false)
    )
}

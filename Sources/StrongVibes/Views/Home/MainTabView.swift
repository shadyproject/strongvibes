import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var homeViewModel: HomeViewModel?
    @State private var selectedTab = 0
    @State private var showingActiveWorkout = false

    var body: some View {
        Group {
            if let viewModel = homeViewModel {
                TabView(selection: $selectedTab) {
                    DashboardView(viewModel: viewModel, showingActiveWorkout: $showingActiveWorkout)
                        .tabItem {
                            Label(String(localized: "Today"), systemImage: "dumbbell.fill")
                        }
                        .tag(0)

                    HistoryView()
                        .tabItem {
                            Label(String(localized: "History"), systemImage: "calendar")
                        }
                        .tag(1)

                    PersonalRecordsView()
                        .tabItem {
                            Label(String(localized: "Records"), systemImage: "trophy.fill")
                        }
                        .tag(2)
                }
                .fullScreenCover(isPresented: $showingActiveWorkout) {
                    if let workout = viewModel.activeWorkout {
                        ActiveWorkoutView(
                            viewModel: ActiveWorkoutViewModel(workout: workout),
                            onComplete: {
                                viewModel.completeWorkout(workout)
                                showingActiveWorkout = false
                            },
                            onCancel: {
                                viewModel.cancelWorkout(workout)
                                showingActiveWorkout = false
                            }
                        )
                    }
                }
            } else {
                ProgressView()
                    .onAppear { setupViewModel() }
            }
        }
        .onAppear { setupViewModel() }
    }

    private func setupViewModel() {
        guard homeViewModel == nil else { return }
        let vm = HomeViewModel(modelContext: modelContext)
        vm.loadProfile()
        homeViewModel = vm
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            WorkoutRecord.self,
            ExercisePerformance.self,
            PersonalRecord.self,
            UserProfile.self,
        ], inMemory: true)
}

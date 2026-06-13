import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var homeViewModel: HomeViewModel?
    @State private var activeWorkoutViewModel: ActiveWorkoutViewModel?
    @State private var selectedTab = 0
    @State private var showingActiveWorkout = false

    var body: some View {
        Group {
            if let viewModel = homeViewModel {
                TabView(selection: $selectedTab) {
                    Tab(String(localized: "Today"), systemImage: "dumbbell.fill", value: 0) {
                        DashboardView(viewModel: viewModel, showingActiveWorkout: $showingActiveWorkout)
                    }
                    Tab(String(localized: "History"), systemImage: "calendar", value: 1) {
                        HistoryView()
                    }
                    Tab(String(localized: "Records"), systemImage: "trophy.fill", value: 2) {
                        PersonalRecordsView()
                    }
                    Tab(String(localized: "Trends"), systemImage: "chart.line.uptrend.xyaxis", value: 3) {
                        TrendsView()
                    }
                }
                .onChange(of: showingActiveWorkout) { _, isShowing in
                    if isShowing, let workout = viewModel.activeWorkout {
                        activeWorkoutViewModel = ActiveWorkoutViewModel(workout: workout)
                    } else if !isShowing {
                        activeWorkoutViewModel = nil
                    }
                }
                .fullScreenCover(isPresented: $showingActiveWorkout) {
                    if let activeVM = activeWorkoutViewModel,
                       let workout = viewModel.activeWorkout {
                        ActiveWorkoutView(
                            viewModel: activeVM,
                            onComplete: {
                                Task { await activeVM.finishHealthKitWorkout() }
                                viewModel.completeWorkout(workout)
                                showingActiveWorkout = false
                            },
                            onCancel: {
                                Task { await activeVM.discardHealthKitWorkout() }
                                viewModel.cancelWorkout(workout)
                                showingActiveWorkout = false
                            }
                        )
                    }
                }
                #if DEBUG
                .devMenuOnShake()
                #endif
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

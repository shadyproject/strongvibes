import SwiftUI
import SwiftData

/// Entry point that routes to onboarding or the main experience.
struct RootView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.onboardingCompleted {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(profiles.first?.appearancePreference.colorScheme)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [
            WorkoutRecord.self,
            ExercisePerformance.self,
            PersonalRecord.self,
            UserProfile.self,
        ], inMemory: true)
}

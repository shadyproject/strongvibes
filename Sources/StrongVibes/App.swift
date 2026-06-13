import SwiftUI
import SwiftData
import UIKit

@main
struct StrongVibesApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear { expandWindowToFullScreen() }
        }
        .modelContainer(for: [
            WorkoutRecord.self,
            ExercisePerformance.self,
            PersonalRecord.self,
            UserProfile.self,
        ])
    }

    @MainActor
    private func expandWindowToFullScreen() {
        let screenBounds = UIScreen.main.bounds
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            windowScene.sizeRestrictions?.minimumSize = screenBounds.size
            windowScene.sizeRestrictions?.maximumSize = screenBounds.size
            for window in windowScene.windows {
                window.frame = screenBounds
            }
        }
    }
}

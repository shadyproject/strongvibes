#if DEBUG
import SwiftUI
import SwiftData

/// Developer menu — only compiled and reachable in DEBUG builds.
struct DevMenuView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingResetConfirmation = false
    @State private var alertMessage: AlertMessage?

    var body: some View {
        NavigationStack {
            List {
                simulatedDataSection
                resetSection
                buildInfoSection
            }
            .navigationTitle("Developer Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset App?", isPresented: $showingResetConfirmation) {
                Button("Reset Everything", role: .destructive) { resetApp() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All workout history, records, and settings are permanently deleted. Onboarding will restart.")
            }
            .alert(item: $alertMessage) { msg in
                Alert(title: Text(msg.title), message: Text(msg.body), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Sections

    private var simulatedDataSection: some View {
        Section {
            ForEach(SimulatedDataGenerator.Period.allCases, id: \.self) { period in
                Button("Add \(period.rawValue) of Data") {
                    generate(period: period)
                }
            }
        } header: {
            Text("Simulated Workout Data")
        } footer: {
            Text("Inserts completed workouts with full weight progression. Existing data is preserved.")
        }
    }

    private var resetSection: some View {
        Section {
            Button("Reset to Initial State", role: .destructive) {
                showingResetConfirmation = true
            }
        } footer: {
            Text("Wipes all SwiftData stores and returns to the onboarding screen.")
        }
    }

    private var buildInfoSection: some View {
        Section("Build Info") {
            LabeledContent("Configuration", value: "DEBUG")
            LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "—")
            LabeledContent("Version", value: Bundle.main.shortVersion)
            LabeledContent("Build", value: Bundle.main.buildNumber)
            LabeledContent("Commit", value: Bundle.main.gitCommitHash)
        }
    }

    // MARK: - Actions

    private func generate(period: SimulatedDataGenerator.Period) {
        do {
            try SimulatedDataGenerator().generate(period: period, in: modelContext)
            alertMessage = AlertMessage(
                title: "Done",
                body: "\(period.rawValue) of workout data inserted successfully."
            )
        } catch {
            alertMessage = AlertMessage(title: "Error", body: error.localizedDescription)
        }
    }

    private func resetApp() {
        do {
            // Delete in dependency order so cascades don't cause constraint violations.
            try modelContext.delete(model: WorkoutRecord.self)
            try modelContext.delete(model: PersonalRecord.self)
            try modelContext.delete(model: UserProfile.self)
            try modelContext.save()
            NotificationCenter.default.post(name: .devMenuDidChange, object: nil)
            dismiss()
        } catch {
            alertMessage = AlertMessage(title: "Reset Failed", body: error.localizedDescription)
        }
    }
}

// MARK: - Helpers

private struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

#Preview {
    DevMenuView()
        .modelContainer(for: [
            WorkoutRecord.self,
            ExercisePerformance.self,
            PersonalRecord.self,
            UserProfile.self,
        ], inMemory: true)
}
#endif

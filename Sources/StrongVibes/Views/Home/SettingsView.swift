import SwiftUI
import SwiftData

struct SettingsView: View {

    var profile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var notificationTime: Date = .now
    @State private var selectedDays: Set<Int> = [2, 4, 6]

    private let weekdays: [(name: String, value: Int)] = [
        ("Sun", 1), ("Mon", 2), ("Tue", 3), ("Wed", 4),
        ("Thu", 5), ("Fri", 6), ("Sat", 7),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Workout Schedule")) {
                    workoutDayPicker
                }
                Section(String(localized: "Reminder Time")) {
                    DatePicker(
                        String(localized: "Notify at"),
                        selection: $notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                Section(String(localized: "Notifications")) {
                    Button(String(localized: "Request Notification Permission")) {
                        Task {
                            await NotificationService.shared.requestAuthorization()
                        }
                    }
                }
                Section {
                    Text("\(Bundle.main.shortVersion) · \(Bundle.main.gitCommitHash)")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveSettings()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
            .onAppear { loadCurrentSettings() }
        }
    }

    private var workoutDayPicker: some View {
        HStack(spacing: 8) {
            ForEach(weekdays, id: \.value) { day in
                let isSelected = selectedDays.contains(day.value)
                Button {
                    if isSelected {
                        selectedDays.remove(day.value)
                    } else {
                        selectedDays.insert(day.value)
                    }
                } label: {
                    Text(day.name)
                        .font(.caption)
                        .fontWeight(isSelected ? .bold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .accessibilityLabel("\(day.name), \(isSelected ? "selected" : "not selected")")
            }
        }
    }

    private func loadCurrentSettings() {
        guard let profile else { return }
        selectedDays = Set(profile.preferredWorkoutDays)
        let hour = profile.notificationHour
        let minute = profile.notificationMinute
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        notificationTime = Calendar.current.date(from: components) ?? .now
    }

    private func saveSettings() {
        guard let profile else { return }
        profile.preferredWorkoutDays = Array(selectedDays).sorted()
        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        profile.notificationHour = components.hour ?? 9
        profile.notificationMinute = components.minute ?? 0
    }
}

#Preview {
    SettingsView(profile: nil)
}

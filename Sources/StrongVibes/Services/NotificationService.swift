import Foundation
import UserNotifications

/// Schedules and manages local workout reminder notifications.
@MainActor
final class NotificationService {

    // MARK: - Properties

    static let shared = NotificationService()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let workoutReminderID = "workout-reminder"

    // MARK: - Initialization

    private init() {}

    // MARK: - Authorization

    /// Requests notification authorization. Returns whether permission was granted.
    func requestAuthorization() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationCenter.notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedules a repeating workout reminder at the next scheduled workout date.
    func scheduleWorkoutReminder(
        for nextDate: Date,
        workoutType: WorkoutType
    ) async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [workoutReminderID]
        )

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time to lift")
        content.body = String(localized: "\(workoutType.displayName) is scheduled for today.")
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: nextDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: workoutReminderID,
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    func cancelWorkoutReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [workoutReminderID])
    }
}

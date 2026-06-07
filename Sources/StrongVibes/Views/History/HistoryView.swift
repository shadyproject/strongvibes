import SwiftUI
import SwiftData

struct HistoryView: View {

    @Query(
        filter: #Predicate<WorkoutRecord> { $0.isCompleted },
        sort: \WorkoutRecord.date
    )
    private var workouts: [WorkoutRecord]

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedWorkout: WorkoutRecord?

    private static let weekdayInitials = ["S", "M", "T", "W", "T", "F", "S"]
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigationHeader
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                weekdayLabels

                Divider()

                if workouts.isEmpty {
                    emptyState
                } else {
                    calendarGrid
                }

                legend
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            .navigationTitle(String(localized: "History"))
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }

    // MARK: - Subviews

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "Previous month"))

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "Next month"))
            .disabled(isDisplayingCurrentMonth)
        }
    }

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Text(Self.weekdayInitials[index])
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    private var calendarGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 0) {
                ForEach(gridDays, id: \.self) { date in
                    DayCell(
                        date: date,
                        workout: workoutLookup[dayKey(date)],
                        isCurrentMonth: isInDisplayedMonth(date),
                        onTap: { selectedWorkout = $0 }
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
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
                .padding(.horizontal)
            Spacer()
        }
    }

    private var legend: some View {
        HStack(spacing: 20) {
            Spacer()
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(WorkoutType.A.calendarColor)
                    .frame(width: 16, height: 16)
                Text(String(localized: "Workout A"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(WorkoutType.B.calendarColor)
                    .frame(width: 16, height: 16)
                Text(String(localized: "Workout B"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Calendar Math

    /// All dates to display in the grid — leading/trailing days pad to complete 6 full weeks.
    private var gridDays: [Date] {
        let calendar = Calendar.current
        guard let firstOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayedMonth)
        ) else { return [] }

        // firstWeekday is 1=Sun…7=Sat; leading cells fill gap before the 1st.
        let leadingCount = calendar.component(.weekday, from: firstOfMonth) - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30

        var days: [Date] = []

        for offset in stride(from: leadingCount, through: 1, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -offset, to: firstOfMonth) {
                days.append(date)
            }
        }

        for offset in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: offset, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Always fill to 42 cells (6 rows) for a stable, non-jumping grid height.
        while days.count < 42 {
            guard let last = days.last,
                  let next = calendar.date(byAdding: .day, value: 1, to: last)
            else { break }
            days.append(next)
        }

        return days
    }

    /// Maps "YYYY-M-D" keys to workout records for O(1) day lookups.
    private var workoutLookup: [String: WorkoutRecord] {
        workouts.reduce(into: [:]) { dict, workout in
            dict[dayKey(workout.date)] = workout
        }
    }

    private func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private func isInDisplayedMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    private var isDisplayingCurrentMonth: Bool {
        Calendar.current.isDate(displayedMonth, equalTo: .now, toGranularity: .month)
    }

    private func shiftMonth(by delta: Int) {
        guard let shifted = Calendar.current.date(
            byAdding: .month, value: delta, to: displayedMonth
        ) else { return }
        displayedMonth = shifted
    }
}

// MARK: - Day Cell

private struct DayCell: View {

    let date: Date
    let workout: WorkoutRecord?
    let isCurrentMonth: Bool
    let onTap: (WorkoutRecord) -> Void

    private var dayNumber: Int { Calendar.current.component(.day, from: date) }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        Button {
            guard let workout else { return }
            onTap(workout)
        } label: {
            VStack(spacing: 3) {
                dayLabel
                workoutBadge
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(workout == nil)
        .accessibilityLabel(accessibilityLabel)
    }

    private var dayLabel: some View {
        ZStack {
            if isToday {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 30, height: 30)
            }
            Text("\(dayNumber)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(dayForegroundColor)
        }
        .frame(width: 30, height: 30)
    }

    private var workoutBadge: some View {
        Group {
            if let workout {
                Text(workout.workoutType.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 15)
                    .background(workout.workoutType.calendarColor, in: RoundedRectangle(cornerRadius: 4))
            } else {
                Color.clear.frame(width: 22, height: 15)
            }
        }
    }

    private var dayForegroundColor: Color {
        if isToday { return .white }
        if !isCurrentMonth { return Color(.tertiaryLabel) }
        return Color(.label)
    }

    private var accessibilityLabel: String {
        let dateStr = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        guard let workout else { return dateStr }
        return "\(dateStr), \(workout.workoutType.displayName) completed"
    }
}

// MARK: - WorkoutType Calendar Color

extension WorkoutType {
    var calendarColor: Color {
        switch self {
        case .A: return .blue
        case .B: return .orange
        }
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutRecord.self, ExercisePerformance.self], inMemory: true)
}

import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {

    @Query(
        filter: #Predicate<WorkoutRecord> { $0.isCompleted },
        sort: \WorkoutRecord.date
    )
    private var workouts: [WorkoutRecord]

    @State private var selectedExercise: ExerciseDefinition = .squat
    @State private var selectedPoint: WeightDataPoint?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                exercisePicker
                    .padding(.vertical, 12)

                if dataPoints.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            statsRow
                                .padding(.horizontal)

                            progressionChart
                                .padding(.horizontal)

                            if let point = selectedPoint {
                                selectedPointCard(point)
                                    .padding(.horizontal)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .animation(.easeInOut(duration: 0.2), value: selectedPoint?.id)
                }
            }
            .navigationTitle(String(localized: "Trends"))
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Exercise Picker

    private var exercisePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExerciseDefinition.all) { exercise in
                    let isSelected = exercise == selectedExercise
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedExercise = exercise
                            selectedPoint = nil
                        }
                    } label: {
                        Text(exercise.name)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                isSelected
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.12),
                                in: Capsule()
                            )
                            .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .accessibilityLabel(exercise.name)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                label: String(localized: "Current"),
                value: formattedWeight(dataPoints.last?.weight ?? 0)
            )
            StatCard(
                label: String(localized: "Best"),
                value: formattedWeight(dataPoints.max(by: { $0.weight < $1.weight })?.weight ?? 0)
            )
            StatCard(
                label: String(localized: "Sessions"),
                value: "\(dataPoints.count)"
            )
            StatCard(
                label: String(localized: "Gained"),
                value: gainedString
            )
        }
    }

    // MARK: - Chart

    private var progressionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Weight over time"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(point.allSetsCompleted ? Color.accentColor : Color.orange)
                    .symbolSize(point == selectedPoint ? 120 : 60)
                }

                if let point = selectedPoint {
                    RuleMark(x: .value("Selected", point.date))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(Int(weight))")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYScale(domain: yAxisDomain)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectPoint(at: value.location, proxy: proxy, geometry: geometry)
                                }
                                .onEnded { _ in
                                    // Keep selection visible after lift
                                }
                        )
                }
            }
            .frame(height: 240)

            // Legend
            HStack(spacing: 16) {
                legendDot(color: .accentColor, label: String(localized: "All sets completed"))
                legendDot(color: .orange, label: String(localized: "Missed sets"))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }

    // MARK: - Selected Point Card

    private func selectedPointCard(_ point: WeightDataPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(point.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formattedWeight(point.weight))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(point.allSetsCompleted
                     ? String(localized: "All sets done")
                     : String(localized: "Missed sets"))
                    .font(.caption)
                    .foregroundStyle(point.allSetsCompleted ? .green : .orange)
                Text(selectedExercise.setsDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(String(localized: "No data yet"))
                .font(.title3)
                .fontWeight(.semibold)
            Text(String(localized: "Complete workouts with \(selectedExercise.name) to see your progression."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }

    // MARK: - Data

    var dataPoints: [WeightDataPoint] {
        workouts.compactMap { workout in
            guard let performance = workout.performances.first(where: {
                $0.exerciseName == selectedExercise.name
            }) else { return nil }
            return WeightDataPoint(
                date: workout.date,
                weight: performance.targetWeight,
                allSetsCompleted: performance.allSetsCompleted
            )
        }
    }

    private var yAxisDomain: ClosedRange<Double> {
        let weights = dataPoints.map(\.weight)
        guard let minWeight = weights.min(), let maxWeight = weights.max() else { return 0...100 }
        let padding = Swift.max(10, (maxWeight - minWeight) * 0.2)
        return (minWeight - padding)...(maxWeight + padding)
    }

    private var gainedString: String {
        guard let first = dataPoints.first?.weight,
              let last = dataPoints.last?.weight
        else { return "—" }
        let gain = last - first
        return gain >= 0 ? "+\(formattedWeight(gain))" : formattedWeight(gain)
    }

    private func formattedWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight)) lbs"
            : "\(weight) lbs"
    }

    private func selectPoint(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        let origin = geometry[proxy.plotFrame!].origin
        let relativeX = location.x - origin.x
        guard let date: Date = proxy.value(atX: relativeX) else { return }

        // Find the data point closest to the tapped date.
        selectedPoint = dataPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }
}

// MARK: - Supporting Types

struct WeightDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let weight: Double
    let allSetsCompleted: Bool
}

// MARK: - Stat Card

private struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - ExerciseDefinition Helpers

private extension ExerciseDefinition {
    var setsDisplay: String { "\(sets)×\(reps)" }
}

#Preview {
    TrendsView()
        .modelContainer(for: [WorkoutRecord.self, ExercisePerformance.self], inMemory: true)
}

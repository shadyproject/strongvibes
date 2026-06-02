import SwiftUI

struct ExerciseSetView: View {

    var performance: ExercisePerformance
    let isCurrent: Bool
    let isCompleted: Bool
    let onSetComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(performance.exerciseName)
                        .font(.headline)
                    Text("\(performance.setsDisplay) @ \(performance.formattedWeight)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                }
            }

            if isCurrent {
                HStack(spacing: 12) {
                    setDots
                    Spacer()
                    Button {
                        onSetComplete()
                    } label: {
                        Text(String(localized: "Set Done"))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel(
                        String(localized: "Complete set \(performance.completedSets + 1) of \(performance.targetSets)")
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .opacity(isCompleted ? 0.6 : 1)
    }

    private var setDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<performance.targetSets, id: \.self) { index in
                Circle()
                    .fill(index < performance.completedSets ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 14, height: 14)
            }
        }
    }
}

#Preview {
    let p = ExercisePerformance(exerciseName: "Squat", targetSets: 5, targetReps: 5, targetWeight: 135)
    p.completedSets = 2
    return VStack(spacing: 12) {
        ExerciseSetView(performance: p, isCurrent: true, isCompleted: false, onSetComplete: {})
        ExerciseSetView(performance: p, isCurrent: false, isCompleted: true, onSetComplete: {})
    }
    .padding()
}

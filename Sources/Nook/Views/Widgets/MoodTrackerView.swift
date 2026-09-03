import SwiftUI

/// "Como você tá hoje?" — tap a face to record today's mood. Tapping the
/// already-picked face clears it. Past days stay in the underlying
/// dictionary even though the card itself only ever shows today.
struct MoodTrackerView: View {
    let data: MoodTracker
    let onChange: (MoodTracker) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("como você tá hoje?")
                .font(Theme.title(14))
                .foregroundStyle(Theme.ink)

            HStack(spacing: 8) {
                ForEach(MoodFace.allCases) { face in
                    faceButton(face)
                }
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .fill(Theme.paper.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                        .stroke(Theme.blush.border.opacity(0.9), lineWidth: 1)
                )
        )
    }

    private func faceButton(_ face: MoodFace) -> some View {
        let isSelected = data.today == face

        return Button {
            var copy = data
            copy.today = isSelected ? nil : face
            onChange(copy)
        } label: {
            LucideIcon(name: face.symbol, size: 18)
                .foregroundStyle(isSelected ? Color.white : Theme.inkSoft)
                .frame(width: 34, height: 34)
                .background(Circle().fill(isSelected ? Theme.accent : Theme.desk.opacity(0.7)))
        }
        .buttonStyle(.plain)
        .help(face.rawValue)
    }
}

import SwiftUI

/// Tap a droplet to set intake. Hover to change how many drops the day needs.
struct WaterTrackView: View {
    let data: WaterTrack
    let onChange: (WaterTrack) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("água")
                    .font(Theme.title(15))
                    .foregroundStyle(Theme.ink)

                if isHovering {
                    stepper
                }

                Spacer()

                Text(String(format: "%.1fL", data.totalLiters))
                    .font(Theme.hand(13, weight: .semibold))
                    .foregroundStyle(Theme.water.accent)
            }

            HStack(spacing: 7) {
                ForEach(0..<data.goal, id: \.self) { index in
                    dropBadge(index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .fill(Theme.paper.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                        .stroke(Theme.water.border.opacity(0.8), lineWidth: 1)
                )
        )
        .onHover { isHovering = $0 }
        .contextMenu {
            Picker("por copo", selection: Binding(
                get: { data.litersPerDrop },
                set: { value in
                    var copy = data
                    copy.litersPerDrop = value
                    onChange(copy)
                }
            )) {
                Text("200ml").tag(0.20)
                Text("250ml").tag(0.25)
                Text("350ml").tag(0.35)
                Text("500ml").tag(0.50)
            }
        }
    }

    /// A filled circle badge rather than a bare drop glyph — pale and
    /// outlined when empty, solid with a white drop once tapped.
    private func dropBadge(_ index: Int) -> some View {
        let isFilled = index < data.filled

        return Circle()
            .fill(isFilled ? Theme.water.accent : Theme.water.pale)
            .overlay(
                LucideIcon(name: "droplet", size: 13)
                    .foregroundStyle(isFilled ? Color.white : Theme.water.accent.opacity(0.55))
            )
            .frame(width: 26, height: 26)
            .contentShape(Circle())
            .onTapGesture {
                var copy = data
                copy.filled = (data.filled == index + 1) ? index : index + 1
                onChange(copy)
            }
    }

    private var stepper: some View {
        HStack(spacing: 2) {
            stepButton("minus", enabled: data.goal > 1) {
                var copy = data
                copy.goal -= 1
                copy.filled = min(copy.filled, copy.goal)
                onChange(copy)
            }
            stepButton("plus", enabled: data.goal < 12) {
                var copy = data
                copy.goal += 1
                onChange(copy)
            }
        }
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LucideIcon(name: symbol, size: 9, weight: 3)
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 14, height: 14)
                .background(Circle().fill(Theme.water.pale))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
    }
}

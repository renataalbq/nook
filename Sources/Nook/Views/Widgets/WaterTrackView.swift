import SwiftUI

/// Tap a droplet to set intake. Hover to change how many drops the day needs.
struct WaterTrackView: View {
    let data: WaterTrack
    let onChange: (WaterTrack) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Water Track")
                    .font(Theme.hand(13, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)

                if isHovering {
                    stepper
                }

                Spacer()

                Text(String(format: "%.1fL", data.totalLiters))
                    .font(Theme.hand(13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }

            HStack(spacing: 7) {
                ForEach(0..<data.goal, id: \.self) { index in
                    Image(systemName: index < data.filled ? "drop.fill" : "drop")
                        .font(.system(size: 19))
                        .foregroundStyle(index < data.filled ? Theme.water : Theme.water.opacity(0.4))
                        .onTapGesture {
                            var copy = data
                            copy.filled = (data.filled == index + 1) ? index : index + 1
                            onChange(copy)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.paper.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.sky.opacity(0.8), lineWidth: 1)
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
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 14, height: 14)
                .background(Circle().fill(Theme.sky.opacity(0.5)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
    }
}

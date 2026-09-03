import SwiftUI

/// A sticker or washi-tape strip — pure decoration, dragged in from the
/// dock. No card background, no editable text: it's just the shape, sitting
/// directly on the page. Rotation is handled one level up, in
/// `CanvasItemView`, since it's the only kind that rotates at all.
struct DecorView: View {
    let data: Decor
    let onChange: (Decor) -> Void

    var body: some View {
        Group {
            if data.kind.isWashi {
                WashiStripesView(tint: data.tint)
            } else {
                LucideIcon(name: data.kind.symbol, size: 32, weight: 2.5)
                    .foregroundStyle(Theme.tint(data.tint).accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .contextMenu {
            Menu("cor") {
                ForEach(TintName.allCases) { tint in
                    Button(tint.rawValue) {
                        var copy = data
                        copy.tint = tint
                        onChange(copy)
                    }
                }
            }
        }
    }
}

/// Diagonal stripes clipped to the strip's own rounded-rect bounds.
private struct WashiStripesView: View {
    let tint: TintName

    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 7
            let spacing: CGFloat = 7
            let color = Theme.tint(tint).accent
            var x = -size.height
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height + stripeWidth, y: size.height))
                path.addLine(to: CGPoint(x: x + stripeWidth, y: 0))
                path.closeSubpath()
                context.fill(path, with: .color(color))
                x += stripeWidth + spacing
            }
        }
        .background(Theme.tint(tint).pale)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Theme.tint(tint).border.opacity(0.4), lineWidth: 1)
        )
    }
}

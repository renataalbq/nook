import SwiftUI

/// Draws the sheet itself: plain, ruled or squared.
struct PaperBackground: View {
    let style: PaperStyle

    private let ruleSpacing = Paper.ruleSpacing
    private let gridSpacing = Paper.gridSpacing

    var body: some View {
        Canvas { context, size in
            switch style {
            case .plain:
                break
            case .ruled:
                var path = Path()
                var y = ruleSpacing
                while y < size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += ruleSpacing
                }
                context.stroke(path, with: .color(Theme.ruleLine), lineWidth: 1)
            case .grid:
                var path = Path()
                var x = gridSpacing
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += gridSpacing
                }
                var y = gridSpacing
                while y < size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += gridSpacing
                }
                context.stroke(path, with: .color(Theme.gridLine.opacity(0.55)), lineWidth: 0.7)
            }
        }
        .background(Theme.paper)
        .allowsHitTesting(false)
    }
}

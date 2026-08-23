import SwiftUI

/// Pen settings that live in the toolbar and drive the drawing layer.
@Observable
final class PenSettings {
    var isActive = false
    var isEraser = false
    var colorHex: UInt32 = 0xE59AAF
    var width: Double = 2.5

    /// How wide a swipe has to pass to a stroke to rub it out.
    var eraserRadius: Double = 12

    static let colors: [UInt32] = [
        0xE59AAF, 0xF0B7C4, 0xB6D8B0, 0x9FC9D8,
        0xB3AEDC, 0xF3C98B, 0x8A7F76, 0x433D38
    ]
    static let widths: [Double] = [1.5, 2.5, 4, 7]
}

/// Renders saved strokes and captures new ones. Only takes hits while the pen
/// is active, so it never blocks the boxes underneath it.
struct DrawingLayer: View {
    let strokes: [Stroke]
    let pen: PenSettings
    let onFinish: (Stroke) -> Void
    let onErase: (CGPoint) -> Void

    @State private var live: [CGPoint] = []

    var body: some View {
        Canvas { context, _ in
            for stroke in strokes {
                context.stroke(
                    path(for: stroke.points),
                    with: .color(Color(nsColor: NSColor(hex: stroke.colorHex))),
                    style: style(width: stroke.width)
                )
            }
            if live.count > 1 {
                context.stroke(
                    path(for: live),
                    with: .color(Color(nsColor: NSColor(hex: pen.colorHex))),
                    style: style(width: pen.width)
                )
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard pen.isActive else { return }
                    if pen.isEraser {
                        onErase(value.location)
                        return
                    }
                    live.append(value.location)
                }
                .onEnded { _ in
                    guard pen.isActive, !pen.isEraser, live.count > 1 else {
                        live = []
                        return
                    }
                    onFinish(Stroke(points: simplify(live), colorHex: pen.colorHex, width: pen.width))
                    live = []
                }
        )
        // Must come last: a modifier only covers what is above it, so putting
        // this before the gesture left an always-live drawing layer on top of
        // the page swallowing every click.
        .allowsHitTesting(pen.isActive)
    }

    private func style(width: Double) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    /// Quadratic smoothing through the midpoints keeps mouse strokes from
    /// looking like polygons.
    private func path(for points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        guard points.count > 2 else {
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            return path
        }

        path.move(to: first)
        for index in 1..<(points.count - 1) {
            let current = points[index]
            let next = points[index + 1]
            let mid = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            path.addQuadCurve(to: mid, control: current)
        }
        path.addLine(to: points[points.count - 1])
        return path
    }

    /// Drops points closer than a pixel or so; a long session otherwise stores
    /// tens of thousands of near-identical coordinates.
    private func simplify(_ points: [CGPoint]) -> [CGPoint] {
        var result: [CGPoint] = []
        for point in points {
            guard let last = result.last else {
                result.append(point)
                continue
            }
            if hypot(point.x - last.x, point.y - last.y) >= 1.2 {
                result.append(point)
            }
        }
        if let last = points.last, result.last != last { result.append(last) }
        return result
    }
}

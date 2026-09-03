import SwiftUI

/// One drawing instruction from a Lucide icon, in its original 24x24
/// authoring box. Curved SVG paths arrive pre-flattened into polylines at
/// generation time (see `LucideGeometry.generated.swift`) — sampled with
/// Python's `svg.path`, which already implements correct SVG arc math — so
/// nothing here needs to parse arcs at runtime.
enum LucidePrimitive {
    case polyline(String)
    case polygon(String)
    case circle(cx: Double, cy: Double, r: Double)
    case rect(x: Double, y: Double, w: Double, h: Double, rx: Double)
    case line(x1: Double, y1: Double, x2: Double, y2: Double)

    func add(to path: inout Path) {
        switch self {
        case .polyline(let raw):
            Self.addPolyline(Self.points(raw), to: &path, closed: false)
        case .polygon(let raw):
            Self.addPolyline(Self.points(raw), to: &path, closed: true)
        case .circle(let cx, let cy, let r):
            path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        case .rect(let x, let y, let w, let h, let rx):
            let frame = CGRect(x: x, y: y, width: w, height: h)
            if rx > 0 {
                path.addRoundedRect(in: frame, cornerSize: CGSize(width: rx, height: rx))
            } else {
                path.addRect(frame)
            }
        case .line(let x1, let y1, let x2, let y2):
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
        }
    }

    private static func addPolyline(_ points: [CGPoint], to path: inout Path, closed: Bool) {
        guard let first = points.first else { return }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        if closed { path.closeSubpath() }
    }

    private static func points(_ raw: String) -> [CGPoint] {
        raw.split(separator: " ").compactMap { pair in
            let parts = pair.split(separator: ",")
            guard parts.count == 2, let x = Double(parts[0]), let y = Double(parts[1]) else { return nil }
            return CGPoint(x: x, y: y)
        }
    }
}

/// A single-weight vector icon from the Lucide set, stroked rather than
/// filled — the app's whole icon language, in place of SF Symbols. Pass the
/// icon's kebab-case Lucide name (e.g. `"chevron-down"`).
struct LucideIcon: View {
    let name: String
    var size: CGFloat = 16
    var weight: CGFloat = 2.75

    var body: some View {
        LucideShape(name: name)
            .stroke(style: StrokeStyle(lineWidth: weight * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

private struct LucideShape: Shape {
    let name: String

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for primitive in lucideGeometry[name] ?? [] {
            primitive.add(to: &path)
        }
        let scale = rect.width / 24
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

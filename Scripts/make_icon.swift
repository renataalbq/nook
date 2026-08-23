import AppKit
import Foundation

// Draws the Nook app icon at 1024pt. Three variants; pick one, then
// Scripts/make_icon.sh turns it into AppIcon.icns.

let size: CGFloat = 1024

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let cream = color(0xFDF9F3)
let paper = color(0xFFFDF8)
let blush = color(0xF2BFCB)
let blushDeep = color(0xE79BAE)
let sage = color(0xB9C9A4)
let sageDeep = color(0x93A87C)
let ink = color(0x6B6058)
let sky = color(0xBBD5E6)

/// The rounded-square plate every macOS icon sits on.
func plate(_ context: CGContext, top: NSColor, bottom: NSColor) {
    let inset: CGFloat = 96
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let path = CGPath(roundedRect: rect, cornerWidth: 190, cornerHeight: 190, transform: nil)

    context.saveGState()
    context.addPath(path)
    context.clip()
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [top.cgColor, bottom.cgColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: 0, y: 0),
        options: []
    )
    context.restoreGState()
}

func roundedRect(_ context: CGContext, _ rect: CGRect, radius: CGFloat, fill: NSColor, rotate: CGFloat = 0) {
    context.saveGState()
    if rotate != 0 {
        context.translateBy(x: rect.midX, y: rect.midY)
        context.rotate(by: rotate * .pi / 180)
        context.translateBy(x: -rect.midX, y: -rect.midY)
    }
    context.setFillColor(fill.cgColor)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
    context.restoreGState()
}

func star(_ context: CGContext, center: CGPoint, radius: CGFloat, fill: NSColor, rotation: CGFloat = 0) {
    let path = CGMutablePath()
    for index in 0..<10 {
        let isOuter = index % 2 == 0
        let r = isOuter ? radius : radius * 0.42
        let angle = rotation + CGFloat(index) * .pi / 5 - .pi / 2
        let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
        index == 0 ? path.move(to: point) : path.addLine(to: point)
    }
    path.closeSubpath()
    context.setFillColor(fill.cgColor)
    context.addPath(path)
    context.fillPath()
}

func line(_ context: CGContext, from: CGPoint, to: CGPoint, width: CGFloat, color: NSColor) {
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.move(to: from)
    context.addLine(to: to)
    context.strokePath()
}

// MARK: - Variant A: closed notebook with a ribbon

func variantA(_ context: CGContext) {
    plate(context, top: cream, bottom: color(0xF7E4E6))

    // Cover, with a page peeking out on the right.
    roundedRect(context, CGRect(x: 300, y: 220, width: 430, height: 580), radius: 46, fill: paper, rotate: -4)
    roundedRect(context, CGRect(x: 280, y: 240, width: 420, height: 570), radius: 46, fill: blush, rotate: -4)

    context.saveGState()
    context.translateBy(x: 490, y: 525)
    context.rotate(by: -4 * .pi / 180)
    context.translateBy(x: -490, y: -525)

    // Ribbon down the spine.
    roundedRect(context, CGRect(x: 322, y: 240, width: 54, height: 570), radius: 8, fill: sage)

    // Ruled lines on the cover.
    for index in 0..<4 {
        let y = 660 - CGFloat(index) * 78
        line(context, from: CGPoint(x: 420, y: y), to: CGPoint(x: 630, y: y), width: 20, color: paper.withAlphaComponent(0.85))
    }
    context.restoreGState()

    star(context, center: CGPoint(x: 726, y: 748), radius: 92, fill: sageDeep)
}

// MARK: - Variant B: open book on grid paper

func variantB(_ context: CGContext) {
    plate(context, top: color(0xFBF7F0), bottom: color(0xE9F0F5))

    roundedRect(context, CGRect(x: 190, y: 300, width: 300, height: 420), radius: 30, fill: paper, rotate: 3)
    roundedRect(context, CGRect(x: 534, y: 300, width: 300, height: 420), radius: 30, fill: paper, rotate: -3)

    // Squares, the default sheet style in the app.
    context.saveGState()
    context.setStrokeColor(sky.withAlphaComponent(0.85).cgColor)
    context.setLineWidth(6)
    for x in stride(from: CGFloat(230), through: 450, by: 55) {
        context.move(to: CGPoint(x: x, y: 330)); context.addLine(to: CGPoint(x: x, y: 700))
    }
    for x in stride(from: CGFloat(574), through: 794, by: 55) {
        context.move(to: CGPoint(x: x, y: 330)); context.addLine(to: CGPoint(x: x, y: 700))
    }
    for y in stride(from: CGFloat(345), through: 690, by: 55) {
        context.move(to: CGPoint(x: 208, y: y)); context.addLine(to: CGPoint(x: 470, y: y))
        context.move(to: CGPoint(x: 554, y: y)); context.addLine(to: CGPoint(x: 816, y: y))
    }
    context.strokePath()
    context.restoreGState()

    // Spine.
    roundedRect(context, CGRect(x: 486, y: 290, width: 52, height: 440), radius: 26, fill: blush)

    star(context, center: CGPoint(x: 762, y: 762), radius: 84, fill: sageDeep)
    star(context, center: CGPoint(x: 252, y: 258), radius: 46, fill: blushDeep)
}

// MARK: - Variant C: handwritten n on a sticky note

func variantC(_ context: CGContext) {
    plate(context, top: color(0xFDF6F7), bottom: color(0xF3DDE3))

    roundedRect(context, CGRect(x: 250, y: 250, width: 524, height: 524), radius: 90, fill: paper, rotate: -5)

    context.saveGState()
    context.translateBy(x: 512, y: 512)
    context.rotate(by: -5 * .pi / 180)
    context.translateBy(x: -512, y: -512)

    context.setStrokeColor(sky.withAlphaComponent(0.7).cgColor)
    context.setLineWidth(5)
    for y in stride(from: CGFloat(300), through: 730, by: 62) {
        context.move(to: CGPoint(x: 285, y: y)); context.addLine(to: CGPoint(x: 739, y: y))
    }
    context.strokePath()

    // A round, hand-drawn "n".
    context.setStrokeColor(blushDeep.cgColor)
    context.setLineWidth(56)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: 400, y: 390))
    context.addLine(to: CGPoint(x: 400, y: 610))
    context.move(to: CGPoint(x: 400, y: 545))
    context.addCurve(
        to: CGPoint(x: 624, y: 545),
        control1: CGPoint(x: 440, y: 660),
        control2: CGPoint(x: 584, y: 660)
    )
    context.addLine(to: CGPoint(x: 624, y: 390))
    context.strokePath()
    context.restoreGState()

    star(context, center: CGPoint(x: 742, y: 750), radius: 78, fill: sageDeep)
}

// MARK: - Render

let variants: [(String, (CGContext) -> Void)] = [("a", variantA), ("b", variantB), ("c", variantC)]
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

for (name, draw) in variants {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { continue }

    NSGraphicsContext.saveGraphicsState()
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = graphics
    draw(graphics.cgContext)
    NSGraphicsContext.restoreGraphicsState()

    let url = URL(fileURLWithPath: "\(outputDir)/icon-\(name).png")
    try? rep.representation(using: .png, properties: [:])?.write(to: url)
    print("wrote \(url.path)")
}

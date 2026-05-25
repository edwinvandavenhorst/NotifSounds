#!/usr/bin/swift
import Cocoa

_ = NSApplication.shared  // initialise AppKit so SF Symbols render

let outDir = NSHomeDirectory() + "/scripts/NotifSoundsApp/icons"
try! FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

struct Style {
    let name: String
    let top: NSColor
    let bottom: NSColor
    let angle: CGFloat
}

let styles: [Style] = [
    // 1 — Indigo / purple
    Style(name: "option1_indigo",
          top:    NSColor(srgbRed: 0.34, green: 0.53, blue: 0.98, alpha: 1),
          bottom: NSColor(srgbRed: 0.50, green: 0.22, blue: 0.93, alpha: 1),
          angle: -45),

    // 2 — Graphite / dark
    Style(name: "option2_graphite",
          top:    NSColor(srgbRed: 0.22, green: 0.24, blue: 0.30, alpha: 1),
          bottom: NSColor(srgbRed: 0.10, green: 0.11, blue: 0.15, alpha: 1),
          angle: -45),

    // 3 — Amber / orange
    Style(name: "option3_amber",
          top:    NSColor(srgbRed: 1.00, green: 0.68, blue: 0.18, alpha: 1),
          bottom: NSColor(srgbRed: 0.97, green: 0.36, blue: 0.08, alpha: 1),
          angle: -45),
]

let size = 512

for style in styles {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ), let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        print("⚠️  Could not create context for \(style.name)"); continue
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let sz = CGFloat(size)
    let rect = NSRect(x: 0, y: 0, width: sz, height: sz)
    let corner = sz * 0.2237

    // Background gradient
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
    NSGradient(colors: [style.top, style.bottom])!.draw(in: bgPath, angle: style.angle)

    // Subtle top highlight
    let hlRect = NSRect(x: sz*0.05, y: sz*0.50, width: sz*0.90, height: sz*0.46)
    let hlPath = NSBezierPath(roundedRect: hlRect, xRadius: corner*0.75, yRadius: corner*0.75)
    let saved = NSGraphicsContext.current?.cgContext
    saved?.saveGState()
    hlPath.addClip()
    NSColor.white.withAlphaComponent(0.08).setFill()
    bgPath.fill()
    saved?.restoreGState()

    // Bell SF Symbol — use paletteColors config for white tint
    let cfg = NSImage.SymbolConfiguration(pointSize: sz * 0.50, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let sym = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: nil)?
                     .withSymbolConfiguration(cfg) {
        let sw = sym.size.width, sh = sym.size.height
        sym.draw(in: NSRect(x: (sz - sw) / 2,
                            y: (sz - sh) / 2 + sz * 0.01,
                            width: sw, height: sh))
    }

    NSGraphicsContext.restoreGraphicsState()

    if let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) {
        let path = outDir + "/" + style.name + ".png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("✓  \(style.name).png")
    }
}

print("Done — icons at ~/scripts/NotifSoundsApp/icons/")

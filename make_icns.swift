#!/usr/bin/swift
// Generates AppIcon.icns for the amber NotifSounds icon.
import Cocoa

_ = NSApplication.shared

let outDir   = NSHomeDirectory() + "/scripts/NotifSoundsApp/icons"
let iconset  = outDir + "/AppIcon.iconset"
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let colorTop    = NSColor(srgbRed: 1.00, green: 0.68, blue: 0.18, alpha: 1)
let colorBottom = NSColor(srgbRed: 0.97, green: 0.36, blue: 0.08, alpha: 1)

func makeRep(pixels: Int) -> NSBitmapImageRep? {
    guard
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixels, pixelsHigh: pixels,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0),
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
    else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let sz = CGFloat(pixels)
    let corner = sz * 0.2237

    // ── transparent canvas (no white bleed at corners) ───────────────────
    ctx.cgContext.clear(CGRect(x: 0, y: 0, width: sz, height: sz))

    // ── gradient background ───────────────────────────────────────────────
    let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: sz, height: sz),
                               xRadius: corner, yRadius: corner)
    NSGradient(colors: [colorTop, colorBottom])!.draw(in: bgPath, angle: -45)

    // ── subtle top-half highlight ─────────────────────────────────────────
    ctx.cgContext.saveGState()
    bgPath.addClip()
    let hlPath = NSBezierPath(roundedRect: NSRect(x: sz*0.04, y: sz*0.50,
                                                   width: sz*0.92, height: sz*0.46),
                               xRadius: corner * 0.75, yRadius: corner * 0.75)
    NSColor.white.withAlphaComponent(0.09).setFill()
    hlPath.fill()
    ctx.cgContext.restoreGState()

    // ── bell SF symbol (white) ────────────────────────────────────────────
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
    return rep
}

func savePNG(_ rep: NSBitmapImageRep, to path: String) {
    guard let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: path))
}

// macOS iconset spec: (logical pt, scale, actual pixels)
let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

var cache: [Int: NSBitmapImageRep] = [:]

for (pt, scale) in sizes {
    let px = pt * scale
    if cache[px] == nil { cache[px] = makeRep(pixels: px) }
    guard let rep = cache[px] else { continue }
    let suffix = scale == 2 ? "@2x" : ""
    let name   = "icon_\(pt)x\(pt)\(suffix).png"
    savePNG(rep, to: iconset + "/" + name)
    print("✓  \(name)  (\(px)×\(px)px)")
}

// Convert iconset → icns
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset, "-o", outDir + "/AppIcon.icns"]
try? task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "✓  AppIcon.icns" : "✗  iconutil failed")

// Save a 512px preview for inspection
if let big = cache[512] { savePNG(big, to: outDir + "/amber_preview.png") }
print("Done.")

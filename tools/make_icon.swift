#!/usr/bin/env swift
import Foundation
import AppKit

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: make_icon.swift <output-iconset-dir>\n".utf8))
    exit(1)
}

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1])

let sizes: [(name: String, size: Int)] = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",    128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",    256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",    512),
    ("icon_512x512@2x.png", 1024),
]

func render(size: CGFloat) -> Data {
    let pixels = Int(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    )!

    NSGraphicsContext.saveGraphicsState()
    let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = nsCtx
    let cg = nsCtx.cgContext

    let pad: CGFloat = size * 0.06
    let bgRect = CGRect(x: pad, y: pad, width: size - 2*pad, height: size - 2*pad)
    let cornerRadius = bgRect.width * 0.225

    // Background: squircle with diagonal cyan→purple→pink gradient (matches popover).
    cg.saveGState()
    NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius).addClip()
    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.30, green: 0.85, blue: 1.00, alpha: 1.0),
        NSColor(srgbRed: 0.55, green: 0.45, blue: 1.00, alpha: 1.0),
        NSColor(srgbRed: 0.95, green: 0.40, blue: 0.75, alpha: 1.0),
    ])!
    gradient.draw(in: bgRect, angle: -45)
    cg.restoreGState()

    // Foreground: SF Symbol "laptopcomputer", tinted white, drop-shadowed, tilted.
    let symbolPointSize = bgRect.width * 0.52
    let config = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .medium)
    if let baseSymbol = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: nil),
       let symbolImage = baseSymbol.withSymbolConfiguration(config) {

        // Build a white-tinted copy of the template symbol so we can draw it
        // directly with NSImage (which handles orientation/flip correctly).
        let tinted = NSImage(size: symbolImage.size)
        tinted.lockFocus()
        NSColor.white.set()
        NSRect(origin: .zero, size: symbolImage.size).fill()
        symbolImage.draw(
            at: .zero,
            from: .zero,
            operation: .destinationIn,
            fraction: 1.0
        )
        tinted.unlockFocus()

        cg.saveGState()
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 0, height: -size * 0.012)
        shadow.shadowBlurRadius = size * 0.025
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.set()

        // Rotate around the symbol's center to tilt the laptop.
        let rotationDegrees: CGFloat = 0
        cg.translateBy(x: bgRect.midX, y: bgRect.midY)
        cg.rotate(by: rotationDegrees * .pi / 180)

        let drawRect = NSRect(
            x: -tinted.size.width / 2,
            y: -tinted.size.height / 2,
            width: tinted.size.width,
            height: tinted.size.height
        )
        tinted.draw(
            in: drawRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        cg.restoreGState()
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
for (name, size) in sizes {
    let data = render(size: CGFloat(size))
    let url = outputDir.appendingPathComponent(name)
    try data.write(to: url)
    print("wrote \(name) (\(size)x\(size))")
}

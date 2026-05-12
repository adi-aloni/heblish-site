// Generate the site's image assets (icon variants + Open Graph share card).
// Run with:  swift make_assets.swift
//
// Produces, into ./assets/ :
//   • icon-64.png, icon-512.png    — used in the topbar and hero
//   • favicon-32.png, favicon-256.png — favicons
//   • og-image.png (1200×630)      — social sharing card

import AppKit
import Foundation

let projectDir = FileManager.default.currentDirectoryPath
let assetsDir = projectDir + "/assets"
try? FileManager.default.createDirectory(
    atPath: assetsDir, withIntermediateDirectories: true, attributes: nil)

/// Draw the rounded-square "א/A" tile used as the app icon.
func renderIcon(size: Int) -> Data? {
    let s = CGFloat(size)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 32
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let inset: CGFloat = s * 0.04
    let rect = NSRect(x: inset, y: inset, width: s - 2*inset, height: s - 2*inset)
    let radius = (s - 2*inset) * 0.225

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.26, alpha: 1.0),
        NSColor(calibratedRed: 0.22, green: 0.30, blue: 0.46, alpha: 1.0),
    ])!
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    gradient.draw(in: rect, angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    let fontSize = s * 0.48
    let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .paragraphStyle: para,
        .kern: -fontSize * 0.04,
    ]
    let text = NSAttributedString(string: "א/A", attributes: attrs)
    let tSize = text.size()
    let textRect = NSRect(
        x: 0,
        y: (s - tSize.height) / 2 - s * 0.025,
        width: s,
        height: tSize.height
    )
    text.draw(in: textRect)
    return bitmap.representation(using: .png, properties: [:])
}

/// Draw the wider Open Graph card: app tile on the left, name + tagline on the right.
func renderOG(width: Int, height: Int) -> Data? {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 32
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    // Background gradient matching the site dark theme
    let bgRect = NSRect(x: 0, y: 0, width: width, height: height)
    let bgGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.055, green: 0.078, blue: 0.133, alpha: 1.0),
        NSColor(calibratedRed: 0.122, green: 0.165, blue: 0.267, alpha: 1.0),
    ])!
    bgGradient.draw(in: bgRect, angle: 120)

    // App icon tile, left
    let tileSize: CGFloat = 280
    let tilePadding: CGFloat = 80
    let tileX = tilePadding
    let tileY = (CGFloat(height) - tileSize) / 2
    let tileRect = NSRect(x: tileX, y: tileY, width: tileSize, height: tileSize)
    let tilePath = NSBezierPath(
        roundedRect: tileRect,
        xRadius: tileSize * 0.225, yRadius: tileSize * 0.225)
    NSGraphicsContext.saveGraphicsState()
    tilePath.addClip()
    let tileGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.26, alpha: 1.0),
        NSColor(calibratedRed: 0.32, green: 0.42, blue: 0.62, alpha: 1.0),
    ])!
    tileGradient.draw(in: tileRect, angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    let tileFontSize = tileSize * 0.48
    let tileFont = NSFont.systemFont(ofSize: tileFontSize, weight: .semibold)
    let tilePara = NSMutableParagraphStyle()
    tilePara.alignment = .center
    let tileText = NSAttributedString(string: "א/A", attributes: [
        .font: tileFont,
        .foregroundColor: NSColor.white,
        .paragraphStyle: tilePara,
        .kern: -tileFontSize * 0.04,
    ])
    let tileTSize = tileText.size()
    tileText.draw(in: NSRect(
        x: tileX, y: tileY + (tileSize - tileTSize.height)/2 - tileSize * 0.025,
        width: tileSize, height: tileTSize.height))

    // Right column: name + tagline
    let textX = tileX + tileSize + 60
    let textRight = CGFloat(width) - tilePadding
    let textWidth = textRight - textX

    let title = NSAttributedString(string: "Heblish", attributes: [
        .font: NSFont.systemFont(ofSize: 96, weight: .bold),
        .foregroundColor: NSColor.white,
        .kern: -1.5,
    ])
    let tagline = NSAttributedString(string: "Hebrew / English keyboard\nautocorrect for macOS", attributes: [
        .font: NSFont.systemFont(ofSize: 36, weight: .regular),
        .foregroundColor: NSColor(white: 0.85, alpha: 1.0),
    ])
    let titleSize = title.boundingRect(
        with: NSSize(width: textWidth, height: 200),
        options: [.usesLineFragmentOrigin])
    let taglineSize = tagline.boundingRect(
        with: NSSize(width: textWidth, height: 300),
        options: [.usesLineFragmentOrigin])

    let totalH = titleSize.height + 28 + taglineSize.height
    let startY = (CGFloat(height) - totalH) / 2
    title.draw(in: NSRect(x: textX, y: startY + 28 + taglineSize.height,
                          width: textWidth, height: titleSize.height))
    tagline.draw(in: NSRect(x: textX, y: startY,
                            width: textWidth, height: taglineSize.height))

    return bitmap.representation(using: .png, properties: [:])
}

let iconSizes: [Int] = [64, 256, 512]
let faviconSizes: [Int] = [32, 256]

for size in iconSizes {
    guard let data = renderIcon(size: size) else {
        print("failed to render icon-\(size).png"); exit(1)
    }
    let path = assetsDir + "/icon-\(size).png"
    try data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}
for size in faviconSizes {
    guard let data = renderIcon(size: size) else {
        print("failed to render favicon-\(size).png"); exit(1)
    }
    let path = assetsDir + "/favicon-\(size).png"
    try data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

guard let og = renderOG(width: 1200, height: 630) else {
    print("failed to render og-image.png"); exit(1)
}
let ogPath = assetsDir + "/og-image.png"
try og.write(to: URL(fileURLWithPath: ogPath))
print("wrote \(ogPath)")

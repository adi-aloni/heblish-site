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

    // Emerald gradient — matches the Adi Aloni brand palette.
    // Darker base = brand "emerald hover" #1A7856; highlight = a brighter emerald.
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.085, green: 0.420, blue: 0.305, alpha: 1.0), // #166B4E
        NSColor(calibratedRed: 0.180, green: 0.655, blue: 0.490, alpha: 1.0), // #2EA77D
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

    // Cool-white brand background with a subtle mint tint at the bottom.
    let bgRect = NSRect(x: 0, y: 0, width: width, height: height)
    let bgGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.953, green: 0.965, blue: 0.953, alpha: 1.0), // #F3F6F3 cool-white
        NSColor(calibratedRed: 0.902, green: 0.937, blue: 0.910, alpha: 1.0), // #E6EFE8 panel
    ])!
    bgGradient.draw(in: bgRect, angle: 120)

    // App icon tile, left — emerald gradient, matches icons
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
        NSColor(calibratedRed: 0.085, green: 0.420, blue: 0.305, alpha: 1.0), // #166B4E
        NSColor(calibratedRed: 0.180, green: 0.655, blue: 0.490, alpha: 1.0), // #2EA77D
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

    // Right column: name + tagline — ink/sage on cool-white background.
    let textX = tileX + tileSize + 60
    let textRight = CGFloat(width) - tilePadding
    let textWidth = textRight - textX

    let title = NSAttributedString(string: "Heblish", attributes: [
        .font: NSFont.systemFont(ofSize: 96, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.075, green: 0.090, blue: 0.102, alpha: 1.0), // #13171A ink
        .kern: -1.5,
    ])
    let tagline = NSAttributedString(string: "Hebrew / English keyboard\nautocorrect for macOS", attributes: [
        .font: NSFont.systemFont(ofSize: 36, weight: .regular),
        .foregroundColor: NSColor(calibratedRed: 0.392, green: 0.439, blue: 0.416, alpha: 1.0), // #64706A sage
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

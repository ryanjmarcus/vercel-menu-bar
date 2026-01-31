#!/usr/bin/env swift

import Cocoa

// DMG background generator for Vercel Menu Bar
// Matches Vercel design language: #0a0a0a background with teal accent

let width: CGFloat = 600
let height: CGFloat = 400

// Vercel background color
let vercelBackground = NSColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1.0)  // #0a0a0a

func createImage(scale: CGFloat) -> NSImage {
    let scaledWidth = width * scale
    let scaledHeight = height * scale
    
    let image = NSImage(size: NSSize(width: scaledWidth, height: scaledHeight))
    
    image.lockFocus()
    
    // Solid Vercel dark background
    vercelBackground.setFill()
    NSRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight).fill()
    
    // Icon positions (matching create-dmg settings, scaled):
    let iconY: CGFloat = (height - 185) * scale
    let appIconX: CGFloat = 150 * scale
    let applicationsX: CGFloat = 450 * scale
    
    // Minimal chevron arrow
    let arrowCenterX: CGFloat = ((appIconX + applicationsX) / 2) + (10 * scale)
    let arrowY: CGFloat = iconY
    let chevronSize: CGFloat = 12 * scale
    
    let chevronPath = NSBezierPath()
    chevronPath.move(to: NSPoint(x: arrowCenterX - chevronSize/2, y: arrowY + chevronSize))
    chevronPath.line(to: NSPoint(x: arrowCenterX + chevronSize/2, y: arrowY))
    chevronPath.line(to: NSPoint(x: arrowCenterX - chevronSize/2, y: arrowY - chevronSize))
    chevronPath.lineWidth = 2.0 * scale
    chevronPath.lineCapStyle = .round
    chevronPath.lineJoinStyle = .round
    
    // White chevron with slight transparency
    NSColor(white: 1.0, alpha: 0.5).setStroke()
    chevronPath.stroke()
    
    image.unlockFocus()
    
    return image
}

func saveImage(_ image: NSImage, to path: String) throws {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image data"])
    }
    
    try pngData.write(to: URL(fileURLWithPath: path))
    print("Created: \(path)")
}

// Generate 1x
let image1x = createImage(scale: 1.0)
try saveImage(image1x, to: "vercel-menu-bar/Resources/dmg-background.png")

// Generate 2x
let image2x = createImage(scale: 2.0)
try saveImage(image2x, to: "vercel-menu-bar/Resources/dmg-background@2x.png")

print("DMG background images generated successfully!")

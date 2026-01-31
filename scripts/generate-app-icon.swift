#!/usr/bin/env swift
//
//  generate-app-icon.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
//  Generates app icon PNGs from the MenuBarIconView design using ImageRenderer.
//  Run with: swift scripts/generate-app-icon.swift
//

import SwiftUI
import AppKit

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
    
    static let vercelBackground = Color(hex: "0a0a0a")
    static let vercelGreen = Color(hex: "50e3c2")
}

// MARK: - App Icon View

/// Renders the menu bar icon design as an app icon with rounded background
struct AppIconView: View {
    let size: CGFloat
    
    // Proportions matching MenuBarIconView
    private var triangleSize: CGFloat { size * 0.40 }
    private var dotSize: CGFloat { size * 0.14 }
    private var cornerRadius: CGFloat { size * 0.22 }
    
    var body: some View {
        ZStack {
            // Rounded black background (macOS app icon style)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.vercelBackground)
            
            // Triangle with status badge
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: triangleSize, weight: .regular))
                    .foregroundColor(.white)
                    .overlay(
                        // Cutout ring for badge
                        Circle()
                            .frame(width: dotSize + 3, height: dotSize + 3)
                            .blendMode(.destinationOut),
                        alignment: .bottomTrailing
                    )
                    .compositingGroup()
                
                // Status badge (Vercel green = ready)
                Circle()
                    .fill(Color.vercelGreen)
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Icon Generation

struct IconSize {
    let size: Int
    let filename: String
}

let iconSizes: [IconSize] = [
    IconSize(size: 16, filename: "icon_16x16.png"),
    IconSize(size: 32, filename: "icon_16x16@2x.png"),
    IconSize(size: 32, filename: "icon_32x32.png"),
    IconSize(size: 64, filename: "icon_32x32@2x.png"),
    IconSize(size: 128, filename: "icon_128x128.png"),
    IconSize(size: 256, filename: "icon_128x128@2x.png"),
    IconSize(size: 256, filename: "icon_256x256.png"),
    IconSize(size: 512, filename: "icon_256x256@2x.png"),
    IconSize(size: 512, filename: "icon_512x512.png"),
    IconSize(size: 1024, filename: "icon_512x512@2x.png"),
]

@MainActor
func generateIcons() {
    // Get the output directory (AppIcon.appiconset)
    let scriptPath = URL(fileURLWithPath: #file)
    let projectRoot = scriptPath.deletingLastPathComponent().deletingLastPathComponent()
    let outputDir = projectRoot
        .appendingPathComponent("vercel-menu-bar")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Assets.xcassets")
        .appendingPathComponent("AppIcon.appiconset")
    
    print("Generating app icons to: \(outputDir.path)")
    
    for iconSize in iconSizes {
        let view = AppIconView(size: CGFloat(iconSize.size))
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        
        guard let cgImage = renderer.cgImage else {
            print("  ✗ Failed to render \(iconSize.filename)")
            continue
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: iconSize.size, height: iconSize.size))
        
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("  ✗ Failed to create PNG for \(iconSize.filename)")
            continue
        }
        
        let outputPath = outputDir.appendingPathComponent(iconSize.filename)
        
        do {
            try pngData.write(to: outputPath)
            print("  ✓ Generated \(iconSize.filename) (\(iconSize.size)x\(iconSize.size))")
        } catch {
            print("  ✗ Failed to write \(iconSize.filename): \(error)")
        }
    }
    
    print("\nDone! Icons generated in AppIcon.appiconset")
}

// Run the generator on main actor
Task { @MainActor in
    generateIcons()
}

// Keep the script running until the task completes
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))

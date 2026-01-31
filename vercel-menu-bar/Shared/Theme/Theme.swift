//
//  Theme.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import SwiftUI
import AppKit

// MARK: - Vercel Colors

extension Color {
    // Backgrounds
    static let vercelBackground = Color(hex: "0a0a0a")
    static let vercelCardBackground = Color(hex: "0f0f0f")
    static let vercelBorder = Color(hex: "1f1f1f")
    static let vercelHover = Color(hex: "141414")
    
    // Text
    static let vercelPrimaryText = Color(hex: "fafafa")
    static let vercelSecondaryText = Color(hex: "a1a1a1")
    static let vercelTertiaryText = Color(hex: "666666")
    
    // Status Colors (from Geist design system)
    // Ready/Success: Teal-green from Geist green scale
    static let vercelGreen = Color(hex: "50e3c2")
    // Building: Amber/Yellow from Geist amber scale  
    static let vercelYellow = Color(hex: "f5a623")
    // Error: Red from Geist red scale
    static let vercelRed = Color(hex: "ee0000")
    // Blue: Primary accent color
    static let vercelBlue = Color(hex: "0070f3")
    // Gray: Neutral/muted state
    static let vercelGray = Color(hex: "666666")
    
    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Status Color Extension

extension DeploymentStatus {
    var color: Color {
        switch self {
        case .ready:
            return .vercelGreen
        case .building:
            return .vercelYellow
        case .error:
            return .vercelRed
        case .queued:
            return .vercelGray
        case .cancelled:
            return .vercelGray
        }
    }
    
    var icon: String {
        switch self {
        case .ready:
            return "checkmark.circle.fill"
        case .building:
            return "arrow.triangle.2.circlepath"
        case .error:
            return "xmark.circle.fill"
        case .queued:
            return "clock.fill"
        case .cancelled:
            return "minus.circle.fill"
        }
    }
}

// MARK: - Fonts

extension Font {
    // Check if Geist is available, otherwise use system font
    private static func geistFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Try Geist first, fall back to system
        if NSFont(name: "Geist-Regular", size: size) != nil {
            return Font.custom("Geist", size: size).weight(weight)
        }
        return Font.system(size: size, weight: weight)
    }
    
    private static func geistMonoFont(size: CGFloat) -> Font {
        // Try GeistMono first, fall back to system monospaced
        if NSFont(name: "GeistMono-Regular", size: size) != nil {
            return Font.custom("GeistMono", size: size)
        }
        return Font.system(size: size, weight: .regular, design: .monospaced)
    }
    
    static let vercelHeading = Font.system(size: 13, weight: .medium)
    static let vercelBody = Font.system(size: 12, weight: .regular)
    static let vercelCaption = Font.system(size: 11, weight: .regular)
    static let vercelMono = Font.system(size: 11, weight: .regular, design: .monospaced)
    static let vercelMonoSmall = Font.system(size: 10, weight: .regular, design: .monospaced)
}

// MARK: - View Modifiers

struct VercelCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.vercelBackground)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.vercelBorder, lineWidth: 1)
            )
    }
}

struct VercelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.vercelHover : Color.clear)
            .cornerRadius(4)
    }
}

struct VercelRowStyle: ViewModifier {
    var isHovered: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.vercelHover : Color.clear)
    }
}

extension View {
    func vercelCard() -> some View {
        modifier(VercelCardStyle())
    }
    
    func vercelRow(isHovered: Bool = false) -> some View {
        modifier(VercelRowStyle(isHovered: isHovered))
    }
}

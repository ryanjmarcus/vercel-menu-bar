//
//  IconButton.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Icon Action Button

/// A small icon button with border styling
struct IconActionButton: View {
    let systemName: String
    let action: () -> Void
    let isDestructive: Bool
    
    @State private var isHovered = false
    
    init(systemName: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.systemName = systemName
        self.isDestructive = isDestructive
        self.action = action
    }
    
    // Geist red-subtle colors for dark mode
    private let redSubtleBackground = Color(red: 0.18, green: 0.08, blue: 0.09) // ~#2d1416
    private let redSubtleBorder = Color(red: 0.35, green: 0.12, blue: 0.14) // ~#591e24
    private let redSubtleIcon = Color(red: 1.0, green: 0.45, blue: 0.45) // ~#ff7373
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 16, height: 16)
                .frame(width: 32, height: 32)
                .background(backgroundColor)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .fixedSize()
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    private var iconColor: Color {
        if isDestructive && isHovered {
            return redSubtleIcon
        }
        return .vercelSecondaryText
    }
    
    private var backgroundColor: Color {
        if isDestructive && isHovered {
            return redSubtleBackground
        }
        if isHovered {
            return Color.vercelHover
        }
        return Color.vercelBackground
    }
    
    private var borderColor: Color {
        if isDestructive && isHovered {
            return redSubtleBorder
        }
        return Color.vercelBorder
    }
}

// MARK: - Hoverable Button

/// A reusable button with hover background effect matching Vercel's style
struct HoverableButton<Content: View>: View {
    let action: () -> Void
    let disabled: Bool
    @ViewBuilder let content: () -> Content
    
    @State private var isHovered = false
    
    init(action: @escaping () -> Void, disabled: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.disabled = disabled
        self.content = content
    }
    
    var body: some View {
        Button(action: action) {
            content()
                .background(isHovered && !disabled ? Color.vercelHover : Color.vercelBackground)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.vercelBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
            if hovering && !disabled {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

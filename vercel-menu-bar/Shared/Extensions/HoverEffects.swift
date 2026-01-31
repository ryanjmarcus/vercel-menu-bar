//
//  HoverEffects.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Pointer Hover Effect

/// A view modifier that shows a pointing hand cursor on hover
struct PointerHoverEffect: ViewModifier {
    let disabled: Bool
    
    init(disabled: Bool = false) {
        self.disabled = disabled
    }
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering && !disabled {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Hoverable Row Effect

/// A view modifier that provides hover highlighting for list rows
struct HoverableRowEffect: ViewModifier {
    @State private var isHovered = false
    let disabled: Bool
    
    init(disabled: Bool = false) {
        self.disabled = disabled
    }
    
    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.vercelHover : Color.clear)
            .onHover { hovering in
                isHovered = hovering
                if hovering && !disabled {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Underline Hover Effect

/// A view modifier that adds an underline on hover (like web links)
struct UnderlineHoverEffect: ViewModifier {
    @State private var isHovered = false
    let disabled: Bool
    
    init(disabled: Bool = false) {
        self.disabled = disabled
    }
    
    func body(content: Content) -> some View {
        content
            .underline(isHovered && !disabled)
            .onHover { hovering in
                isHovered = hovering
                if hovering && !disabled {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Hoverable Button Effect

/// A view modifier that provides subtle hover highlighting for buttons and controls
struct HoverableButtonEffect: ViewModifier {
    @State private var isHovered = false
    let disabled: Bool
    let cornerRadius: CGFloat
    
    init(disabled: Bool = false, cornerRadius: CGFloat = 4) {
        self.disabled = disabled
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered && !disabled ? Color.vercelHover : Color.clear)
            )
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

// MARK: - View Extensions

extension View {
    /// Adds a pointing hand cursor on hover
    func pointerOnHover(disabled: Bool = false) -> some View {
        modifier(PointerHoverEffect(disabled: disabled))
    }
    
    /// Adds hover highlighting and pointer cursor for list rows
    func hoverableRow(disabled: Bool = false) -> some View {
        modifier(HoverableRowEffect(disabled: disabled))
    }
    
    /// Adds an underline on hover (like web links)
    func underlineOnHover(disabled: Bool = false) -> some View {
        modifier(UnderlineHoverEffect(disabled: disabled))
    }
    
    /// Adds subtle hover highlighting for buttons and controls
    func hoverableButton(disabled: Bool = false, cornerRadius: CGFloat = 4) -> some View {
        modifier(HoverableButtonEffect(disabled: disabled, cornerRadius: cornerRadius))
    }
}

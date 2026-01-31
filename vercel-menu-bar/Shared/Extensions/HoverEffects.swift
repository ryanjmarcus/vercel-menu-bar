//
//  HoverEffects.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
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
}

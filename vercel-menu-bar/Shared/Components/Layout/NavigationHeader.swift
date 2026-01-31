//
//  NavigationHeader.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Back Button

/// A styled back button with chevron and "Back" text
struct BackButton: View {
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Back")
                    .font(.vercelBody)
            }
            .foregroundColor(isHovered ? .vercelSecondaryTextHover : .vercelSecondaryText)
        }
        .buttonStyle(.plain)
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
}

// MARK: - Navigation Header

/// A header with back button, optional centered title, and optional trailing actions
struct NavigationHeader<TrailingContent: View>: View {
    let onBack: () -> Void
    let title: String?
    @ViewBuilder let trailingContent: TrailingContent
    
    init(
        onBack: @escaping () -> Void,
        title: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.onBack = onBack
        self.title = title
        self.trailingContent = trailingContent()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Centered title
                if let title = title {
                    Text(title)
                        .font(.vercelHeading)
                        .foregroundColor(.vercelPrimaryText)
                }
                
                // Back button on left, trailing content on right
                HStack(spacing: 12) {
                    BackButton(action: onBack)
                    
                    Spacer()
                    
                    trailingContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.vercelBorder)
        }
    }
}

// MARK: - Icon Button

/// A small icon button for header actions
struct IconButton: View {
    let systemName: String
    let action: () -> Void
    let isLoading: Bool
    let disabled: Bool
    
    @State private var isHovered = false
    
    init(
        systemName: String,
        isLoading: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.isLoading = isLoading
        self.disabled = disabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isHovered && !disabled ? .vercelSecondaryTextHover : .vercelSecondaryText)
                .rotationEffect(.degrees(isLoading ? 360 : 0))
                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
        }
        .buttonStyle(.plain)
        .disabled(disabled || isLoading)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
            if hovering && !disabled && !isLoading {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Close Button

/// A close button that closes the popover
struct CloseButton: View {
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isHovered ? .vercelSecondaryTextHover : .vercelSecondaryText)
        }
        .buttonStyle(.plain)
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
}

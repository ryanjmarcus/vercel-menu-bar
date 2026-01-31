//
//  NavigationHeader.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI
import AppKit

// MARK: - Back Button

/// A styled back button with chevron and "Back" text
struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Back")
                    .font(.vercelBody)
            }
            .foregroundColor(.vercelSecondaryText)
        }
        .buttonStyle(.plain)
        .pointerOnHover()
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
            HStack(spacing: 12) {
                BackButton(action: onBack)
                
                if let title = title {
                    Spacer()
                    
                    Text(title)
                        .font(.vercelHeading)
                        .foregroundColor(.vercelPrimaryText)
                    
                    Spacer()
                    
                    // Invisible spacer to balance
                    BackButton(action: {})
                        .opacity(0)
                } else {
                    Spacer()
                }
                
                trailingContent
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
                .foregroundColor(.vercelSecondaryText)
                .rotationEffect(.degrees(isLoading ? 360 : 0))
                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
        }
        .buttonStyle(.plain)
        .disabled(disabled || isLoading)
        .pointerOnHover(disabled: disabled || isLoading)
    }
}

// MARK: - Close Button

/// A close button that terminates the app
struct CloseButton: View {
    var body: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.vercelSecondaryText)
        }
        .buttonStyle(.plain)
        .pointerOnHover()
    }
}

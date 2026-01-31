//
//  UIComponents.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Section Header

/// A header for list sections with optional action button
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.vercelHeading)
                .foregroundColor(.vercelPrimaryText)
            
            Spacer()
            
            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.vercelCaption)
                        .foregroundColor(.vercelSecondaryText)
                }
                .buttonStyle(.plain)
                .pointerOnHover()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Empty State View

/// A view shown when there's no content to display
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            EmptyStateIcon(systemName: icon)
            
            // Text
            VStack(spacing: 6) {
                Text(title)
                    .font(.vercelHeading)
                    .foregroundColor(.vercelPrimaryText)
                
                Text(message)
                    .font(.vercelCaption)
                    .foregroundColor(.vercelSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Button
            if let buttonTitle = buttonTitle, let action = action {
                ActionButton(title: buttonTitle, action: action)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

// MARK: - Empty State Icon

/// The icon shown in empty state views
private struct EmptyStateIcon: View {
    let systemName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.vercelBackground)
                .frame(width: 64, height: 64)
            
            Circle()
                .stroke(Color.vercelBorder, lineWidth: 1)
                .frame(width: 64, height: 64)
            
            Image(systemName: systemName)
                .font(.system(size: 24))
                .foregroundColor(.vercelSecondaryText)
        }
    }
}

// MARK: - Action Button

/// A styled action button with border
struct ActionButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    
    init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                }
                
                Text(title)
                    .font(.vercelBody)
                    .foregroundColor(.vercelPrimaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.vercelBackground)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.vercelBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .pointerOnHover(disabled: isLoading)
    }
}

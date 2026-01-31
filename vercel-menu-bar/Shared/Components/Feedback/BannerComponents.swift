//
//  BannerComponents.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI

// MARK: - Error Banner

/// A banner displaying an error message with an optional action button
struct ErrorBanner: View {
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        _ message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.vercelYellow)
                
                Text(message)
                    .font(.vercelCaption)
                    .foregroundColor(.vercelSecondaryText)
                
                Spacer()
                
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.vercelCaption)
                            .foregroundColor(.vercelPrimaryText)
                    }
                    .buttonStyle(.plain)
                    .pointerOnHover()
                }
            }
            .padding(12)
            .background(Color.vercelYellow.opacity(0.1))
            
            Divider()
                .background(Color.vercelBorder)
        }
    }
}

// MARK: - Info Banner

/// A banner displaying an informational message
struct InfoBanner: View {
    let message: String
    let icon: String
    
    init(_ message: String, icon: String = "info.circle.fill") {
        self.message = message
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.vercelBlue)
                
                Text(message)
                    .font(.vercelCaption)
                    .foregroundColor(.vercelSecondaryText)
                
                Spacer()
            }
            .padding(12)
            .background(Color.vercelBlue.opacity(0.1))
            
            Divider()
                .background(Color.vercelBorder)
        }
    }
}

// MARK: - Loading View

/// A centered loading view with spinner and optional message
struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
            
            Text(message)
                .font(.vercelCaption)
                .foregroundColor(.vercelSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

//
//  MainHeader.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Main Header

/// The main view header with project info and action buttons
struct MainHeader: View {
    let hasSelectedProject: Bool
    let projectName: String
    let faviconURL: URL?
    let isLoading: Bool
    let refreshRotationAngle: Double
    let onRefresh: () -> Void
    let onSettings: () -> Void
    let onClose: () -> Void
    
    @State private var isRefreshHovered = false
    @State private var isSettingsHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Project info
                HStack(alignment: .center, spacing: 8) {
                    if hasSelectedProject {
                        // Favicon shows nothing while loading (no fallback triangle)
                        ProjectHeaderFavicon(url: faviconURL)
                            .offset(y: 1)
                        
                        Text(projectName)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.vercelPrimaryText)
                    } else {
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.vercelPrimaryText)
                            .frame(width: 16, height: 16)
                        
                        Text("Vercel")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.vercelPrimaryText)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    // Refresh button
                    Button(action: onRefresh) {
                        Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isRefreshHovered && !isLoading ? .vercelSecondaryTextHover : .vercelSecondaryText)
                            .rotationEffect(.degrees(refreshRotationAngle))
                            .animation(
                                isLoading 
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : refreshRotationAngle > 0
                                        ? .spring(response: 0.5, dampingFraction: 0.7)
                                        : nil,
                                value: refreshRotationAngle
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isRefreshHovered = hovering
                        }
                        if hovering && !isLoading {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    
                    // Settings button
                    Button(action: onSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSettingsHovered ? .vercelSecondaryTextHover : .vercelSecondaryText)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isSettingsHovered = hovering
                        }
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    
                    // Close button
                    CloseButton(action: onClose)
                }
            }
            .padding(.top, 2)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider()
                .background(Color.vercelBorder)
        }
    }
}

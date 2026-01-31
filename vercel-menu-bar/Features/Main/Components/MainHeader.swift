//
//  MainHeader.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Project info
                HStack(spacing: 8) {
                    if hasSelectedProject {
                        ProjectHeaderFavicon(url: faviconURL)
                        
                        Text(projectName)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.vercelPrimaryText)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "triangle")
                                .font(.system(size: 14))
                                .foregroundColor(.vercelPrimaryText)
                            
                            Text("/")
                                .font(.vercelHeading)
                                .foregroundColor(.vercelPrimaryText)
                        }
                        
                        Text("Vercel")
                            .font(.vercelHeading)
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
                            .foregroundColor(.vercelSecondaryText)
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
                    .pointerOnHover(disabled: isLoading)
                    
                    // Settings button
                    Button(action: onSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.vercelSecondaryText)
                    }
                    .buttonStyle(.plain)
                    .pointerOnHover()
                    
                    // Close button
                    CloseButton()
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

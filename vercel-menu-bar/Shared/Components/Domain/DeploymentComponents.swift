//
//  DeploymentComponents.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Deployment Row (for list)

struct DeploymentRow: View {
    let deployment: Deployment
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Column 1: Deployment ID + Environment
                VStack(alignment: .leading, spacing: 3) {
                    Text(deployment.shortDeploymentId)
                        .font(.vercelMono)
                        .fontWeight(.semibold)
                        .foregroundColor(.vercelPrimaryText)
                    
                    HStack(spacing: 4) {
                        if let url = deployment.environmentSettingsURL {
                            Button(action: {
                                NSWorkspace.shared.open(url)
                            }) {
                                Text(deployment.environment.displayName)
                                    .font(.vercelCaption)
                                    .foregroundColor(.vercelSecondaryText)
                                    .underlineOnHover()
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(deployment.environment.displayName)
                                .font(.vercelCaption)
                                .foregroundColor(.vercelSecondaryText)
                        }
                        
                        if deployment.isCurrent {
                            CurrentPillSmall()
                                .padding(.leading, 1)
                        } else if deployment.environment == .production {
                            // Show production icon for all production deployments (including building)
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 10))
                                .foregroundColor(.vercelSecondaryText)
                        } else if deployment.environment == .preview {
                            // Show preview icon for all preview deployments (including building)
                            Image(systemName: "eye")
                                .font(.system(size: 9))
                                .foregroundColor(.vercelSecondaryText)
                        }
                    }
                }
                .frame(width: 130, alignment: .leading)
                
                // Column 2: Status + Duration
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        StatusDot(status: deployment.status, animated: deployment.status == .building)
                        Text(deployment.status.rawValue)
                            .font(.vercelBody)
                            .foregroundColor(.vercelSecondaryText)
                    }
                    
                    if deployment.buildDuration != nil || deployment.status == .building || deployment.status == .queued {
                        LiveDurationView(
                            deployment: deployment,
                            showIcon: false,
                            font: .vercelCaption,
                            color: .vercelSecondaryText
                        )
                        .padding(.leading, 14)
                    }
                }
                .frame(width: 90, alignment: .leading)
                
                // Column 3: Git Branch + Commit
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        GitBranchIcon(size: 12, color: .vercelSecondaryText)
                        Text(deployment.branch)
                            .font(.vercelMono)
                            .foregroundColor(.vercelSecondaryText)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    HStack(spacing: 4) {
                        GitCommitIcon(size: 12, color: .vercelSecondaryText)
                        Text(deployment.shortCommitHash)
                            .font(.vercelMono)
                            .foregroundColor(.vercelSecondaryText)
                            .lineLimit(1)
                    }
                }
                .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.vercelTertiaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(isHovered ? Color.vercelHover : Color.clear)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Deployment Card (featured/latest)

struct DeploymentCard: View {
    let deployment: Deployment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Deployment Header
            deploymentHeader
            
            cardDivider
            
            // Status, Duration, Created Row
            statusRow
            
            cardDivider
            
            // Environment Row
            environmentRow
            
            cardDivider
            
            // Domains Section
            DomainsSection(deployment: deployment)
                .padding(12)
            
            cardDivider
            
            // Source Section
            sourceSection
        }
        .background(Color.vercelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.vercelBorder, lineWidth: 1)
        )
    }
    
    private var cardDivider: some View {
        Divider()
            .background(Color.vercelBorder.opacity(0.3))
    }
    
    // MARK: - Deployment Header
    
    private var deploymentHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Deployment")
                .font(.vercelCaption)
                .foregroundColor(.vercelSecondaryText)
            
            HStack(spacing: 6) {
                Text(deployment.shortDeploymentId)
                    .font(.vercelMono)
                    .foregroundColor(.vercelPrimaryText)
                    .lineLimit(1)
                
                CopyButton(deployment.id)
            }
        }
        .padding(12)
    }
    
    // MARK: - Status Row
    
    private var statusRow: some View {
        HStack(spacing: 20) {
            // Status
            DetailField(label: "Status") {
                HStack(spacing: 6) {
                    StatusDot(status: deployment.status, animated: deployment.status == .building)
                    Text(deployment.status.rawValue)
                        .font(.vercelBody)
                        .foregroundColor(.vercelPrimaryText)
                }
            }
            
            // Duration
            if deployment.buildDuration != nil || deployment.status == .building || deployment.status == .queued {
                DetailField(label: "Duration") {
                    LiveDurationView(
                        deployment: deployment,
                        showIcon: true,
                        font: .vercelBody,
                        color: .vercelPrimaryText
                    )
                }
                .padding(.leading, 14)
            }
            
            // Created
            DetailField(label: "Created") {
                HStack(spacing: 4) {
                    AuthorAvatar(deployment: deployment)
                    
                    Text(deployment.author)
                        .font(.vercelBody)
                        .foregroundColor(.vercelPrimaryText)
                        .lineLimit(1)
                    
                    Text(deployment.relativeTime)
                        .font(.vercelBody)
                        .foregroundColor(.vercelSecondaryText)
                }
            }
            .padding(.leading, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }
    
    // MARK: - Environment Row
    
    private var environmentRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Environment")
                .font(.vercelCaption)
                .foregroundColor(.vercelSecondaryText)
            
            HStack(spacing: 5) {
                if deployment.environment == .preview {
                    Image(systemName: "eye")
                        .font(.system(size: 11))
                        .foregroundColor(.vercelSecondaryText)
                } else if deployment.isPromoted {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.vercelSecondaryText)
                }
                
                if let url = deployment.environmentSettingsURL {
                    Button(action: {
                        NSWorkspace.shared.open(url)
                    }) {
                        Text(deployment.environment.displayName)
                            .font(.vercelBody)
                            .foregroundColor(.vercelPrimaryText)
                            .underlineOnHover()
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(deployment.environment.displayName)
                        .font(.vercelBody)
                        .foregroundColor(.vercelPrimaryText)
                }
                
                if deployment.isCurrent {
                    CurrentPill()
                        .padding(.leading, 3)
                }
            }
        }
        .padding(12)
    }
    
    // MARK: - Source Section
    
    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Source")
                .font(.vercelCaption)
                .foregroundColor(.vercelSecondaryText)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    GitBranchIcon(size: 11, color: .vercelSecondaryText)
                    
                    Button(action: {
                        if let url = deployment.githubBranchURL {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text(deployment.branch)
                            .font(.vercelBody)
                            .foregroundColor(.vercelPrimaryText)
                            .underlineOnHover(disabled: !deployment.hasGitHubInfo)
                    }
                    .buttonStyle(.plain)
                    .disabled(!deployment.hasGitHubInfo)
                }
                
                HStack(spacing: 6) {
                    GitCommitIcon(size: 11, color: .vercelSecondaryText)
                    
                    Button(action: {
                        if let url = deployment.githubCommitURL {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text(deployment.shortCommitHash)
                            .font(.vercelMono)
                            .foregroundColor(.vercelPrimaryText)
                            .underlineOnHover(disabled: !deployment.hasGitHubInfo)
                    }
                    .buttonStyle(.plain)
                    .disabled(!deployment.hasGitHubInfo)
                    
                    Text(deployment.truncatedCommitMessage)
                        .font(.vercelCaption)
                        .foregroundColor(.vercelSecondaryText)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Detail Field

/// A labeled field with title and content
private struct DetailField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.vercelCaption)
                .foregroundColor(.vercelSecondaryText)
            
            content
        }
    }
}

// MARK: - Current Pill

/// A pill showing "Current" for the active deployment
private struct CurrentPill: View {
    var body: some View {
        Text("Current")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(Color(hex: "3291ff"))
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(Color(hex: "0070f3").opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "0070f3").opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Current Pill Small

/// A smaller version of CurrentPill for deployment rows with production icon
private struct CurrentPillSmall: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 8))
            Text("Current")
                .font(.system(size: 8, weight: .medium))
        }
        .foregroundColor(Color(hex: "3291ff"))
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(Color(hex: "0070f3").opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "0070f3").opacity(0.15), lineWidth: 1)
        )
    }
}

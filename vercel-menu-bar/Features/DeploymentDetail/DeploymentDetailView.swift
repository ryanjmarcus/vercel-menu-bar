//
//  DeploymentDetailView.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import SwiftUI
import AppKit

struct DeploymentDetailView: View {
    let deployment: Deployment
    let onBack: () -> Void
    
    private var deploymentURL: String {
        let projectName = deployment.projectName
        
        // Extract team from deployment name
        // Format: "project-hash-team.vercel.app" (e.g., "my-app-abc123-team.vercel.app")
        // Team is at the END before .vercel.app
        var teamSlug: String? = nil
        
        // Remove .vercel.app suffix if present
        var cleanName = deployment.name
        if cleanName.hasSuffix(".vercel.app") {
            cleanName = String(cleanName.dropLast(".vercel.app".count))
        }
        
        // Split by "-" and get the last component as team
        let nameComponents = cleanName.components(separatedBy: "-")
        if nameComponents.count >= 2 {
            // Last component is the team
            teamSlug = nameComponents.last
        }
        
        // Use the full deployment ID
        let deploymentId = deployment.id
        
        // Construct deployment URL: https://vercel.com/[team]/[project]/[deployment-id]
        let encodedProjectName = projectName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? projectName
        let encodedDeploymentId = deploymentId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? deploymentId
        
        if let team = teamSlug, !team.isEmpty {
            let encodedTeam = team.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? team
            return "https://vercel.com/\(encodedTeam)/\(encodedProjectName)/\(encodedDeploymentId)"
        } else {
            return "https://vercel.com/\(encodedProjectName)/\(encodedDeploymentId)"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            NavigationHeader(onBack: onBack) {
                ExternalLinkButton("Open in Vercel", urlString: deploymentURL)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    deploymentCard
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color.vercelBackground)
    }
    
    // MARK: - Deployment Card
    
    private var deploymentCard: some View {
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
            
            HStack(spacing: 6) {
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
                        .padding(.leading, 4)
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
            .font(.vercelCaption)
            .foregroundColor(Color(hex: "3291ff"))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: "0070f3").opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "0070f3").opacity(0.15), lineWidth: 1)
            )
    }
}

#Preview {
    DeploymentDetailView(
        deployment: Deployment.dummyDeployments[0],
        onBack: {}
    )
    .frame(width: 380, height: 520)
}

//
//  OverviewSection.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI

// MARK: - Overview Section

/// The overview section showing the latest deployment
struct OverviewSection: View {
    let deployment: Deployment
    let project: VercelProject?
    
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Recent")
                    .font(.vercelCaption)
                    .foregroundColor(.vercelSecondaryText)

                Spacer()
                
                ExternalLinkButton("Open in Vercel", urlString: deploymentURL)
            }
            .padding(.top, -1.5)
            
            DeploymentCard(deployment: deployment)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }
}

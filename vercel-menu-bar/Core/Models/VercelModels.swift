//
//  VercelModels.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import Foundation

// MARK: - API Response Models

struct VercelDeploymentsResponse: Codable {
    let deployments: [VercelDeployment]
    let pagination: VercelPagination?
}

struct VercelProjectsResponse: Codable {
    let projects: [VercelProject]
    let pagination: VercelPagination?
}

struct VercelProjectAlias: Codable {
    let domain: String?
    let target: String?
}

struct VercelLatestDeployment: Codable {
    let id: String?
    let uid: String?
    let url: String?
    let alias: [String]?
    let readyState: String?
    
    // Computed property to get deployment ID from either id or uid
    var deploymentId: String? {
        return id ?? uid
    }
}

struct VercelProject: Codable, Identifiable {
    let id: String
    let name: String
    let accountId: String?
    let createdAt: Int64?
    let updatedAt: Int64?
    let framework: String?
    let alias: [VercelProjectAlias]?
    let latestDeployments: [VercelLatestDeployment]?
    
    /// Returns the first custom domain for this project (not Vercel defaults)
    var productionDomain: String? {
        // First, check latestDeployments alias array (this is where custom domains appear)
        if let deployments = latestDeployments {
            for deployment in deployments {
                if let aliases = deployment.alias {
                    // Find the first custom domain (not a .vercel.app domain)
                    for domain in aliases {
                        if !domain.isEmpty && !domain.hasSuffix(".vercel.app") {
                            return domain
                        }
                    }
                }
            }
        }
        
        // Fall back to project-level alias array
        if let aliases = alias {
            for aliasItem in aliases {
                if let domain = aliasItem.domain,
                   !domain.isEmpty,
                   !domain.hasSuffix(".vercel.app") {
                    return domain
                }
            }
        }
        
        // No custom domain found
        return nil
    }
    
    /// Returns the favicon URL for this project using Vercel's API
    /// Uses Vercel's favicon endpoint for all projects, regardless of domain
    var faviconURL: URL? {
        // Use Vercel's favicon API endpoint
        guard let deployments = latestDeployments,
              !deployments.isEmpty,
              let firstDeployment = deployments.first,
              let deploymentId = firstDeployment.deploymentId,
              !deploymentId.isEmpty,
              let accountId = accountId,
              !accountId.isEmpty else {
            return nil
        }
        
        let readyState = firstDeployment.readyState ?? "READY"
        
        // Safely encode URL components
        guard let encodedProject = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedReadyState = readyState.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedDeploymentId = deploymentId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedAccountId = accountId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        // Vercel's favicon API pattern: /api/v0/deployments/{id}/favicon?project={name}&readyState={state}&teamId={teamId}&dpl={id}
        let urlString = "https://vercel.com/api/v0/deployments/\(encodedDeploymentId)/favicon?project=\(encodedProject)&readyState=\(encodedReadyState)&teamId=\(encodedAccountId)&dpl=\(encodedDeploymentId)"
        
        // Safely create URL - return nil if URL construction fails
        guard let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
}

struct VercelPagination: Codable {
    let count: Int?
    let next: Int64?
    let prev: Int64?
}

struct VercelDeployment: Codable {
    let uid: String
    let name: String
    let url: String?
    let state: String?
    let readyState: String?
    let readySubstate: String?
    let created: Int64?
    let createdAt: Int64?
    let creator: VercelCreator?
    let meta: VercelMeta?
    let target: String?
    let inspectorUrl: String?
    let projectId: String?
    let buildingAt: Int64?
    let ready: Int64?
    let alias: [String]?
    let aliasAssigned: Int64?
    
    /// Computed build duration in seconds
    var computedBuildDuration: TimeInterval? {
        guard let buildingAt = buildingAt, let ready = ready else { return nil }
        let duration = TimeInterval(ready - buildingAt) / 1000.0
        return duration > 0 ? duration : nil
    }
}

struct VercelCreator: Codable {
    let uid: String?
    let email: String?
    let username: String?
    let githubLogin: String?
}

struct VercelMeta: Codable {
    let githubCommitSha: String?
    let githubCommitMessage: String?
    let githubCommitRef: String?
    let githubRepo: String?
    let githubOrg: String?
    let gitlabCommitSha: String?
    let gitlabCommitMessage: String?
    let gitlabCommitRef: String?
    let bitbucketCommitSha: String?
    let bitbucketCommitMessage: String?
    let bitbucketCommitRef: String?
}

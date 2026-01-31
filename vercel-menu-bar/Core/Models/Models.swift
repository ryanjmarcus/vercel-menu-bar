//
//  Models.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import Foundation

enum DeploymentStatus: String, CaseIterable {
    case ready = "Ready"
    case building = "Building"
    case error = "Error"
    case queued = "Queued"
    case cancelled = "Cancelled"
}

enum DeploymentEnvironment: String {
    case production = "production"
    case preview = "preview"
    case development = "development"
    
    var displayName: String {
        switch self {
        case .production:
            return "Production"
        case .preview:
            return "Preview"
        case .development:
            return "Development"
        }
    }
}

struct Deployment: Identifiable, Equatable {
    let id: String
    let name: String
    let projectName: String
    let domains: [String]
    let status: DeploymentStatus
    let createdAt: Date
    let author: String
    let authorGithubUsername: String?
    let branch: String
    let commitHash: String
    let commitMessage: String
    let buildDuration: TimeInterval?
    let githubOrg: String?
    let githubRepo: String?
    let environment: DeploymentEnvironment
    let isCurrent: Bool
    let isPromoted: Bool
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var shortCommitHash: String {
        String(commitHash.prefix(7))
    }
    
    var shortDeploymentId: String {
        let idWithoutPrefix = id.hasPrefix("dpl_") ? String(id.dropFirst(4)) : id
        return String(idWithoutPrefix.prefix(9))
    }
    
    var truncatedCommitMessage: String {
        if commitMessage.count > 50 {
            return String(commitMessage.prefix(47)) + "..."
        }
        return commitMessage
    }
    
    /// Returns the GitHub commit URL if available
    var githubCommitURL: URL? {
        guard let org = githubOrg, let repo = githubRepo, !commitHash.isEmpty else {
            return nil
        }
        return URL(string: "https://github.com/\(org)/\(repo)/commit/\(commitHash)")
    }
    
    /// Returns the GitHub branch URL if available
    var githubBranchURL: URL? {
        guard let org = githubOrg, let repo = githubRepo, !branch.isEmpty else {
            return nil
        }
        return URL(string: "https://github.com/\(org)/\(repo)/tree/\(branch)")
    }
    
    /// Returns true if this deployment has GitHub information
    var hasGitHubInfo: Bool {
        githubOrg != nil && githubRepo != nil
    }
    
    /// Returns the favicon URL for this deployment based on its first domain
    var faviconURL: URL? {
        guard let domain = domains.first else { return nil }
        // Try direct favicon.ico first, then fall back to Google's service
        if let directURL = URL(string: "https://\(domain)/favicon.ico") {
            return directURL
        }
        // Fallback to Google's favicon service
        return URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=32")
    }
    
    /// Returns the environment settings URL for this deployment
    var environmentSettingsURL: URL? {
        // Extract team from deployment name
        // Format: "project-hash-team.vercel.app" (e.g., "my-app-abc123-team.vercel.app")
        var teamSlug: String? = nil
        
        // Remove .vercel.app suffix if present
        var cleanName = name
        if cleanName.hasSuffix(".vercel.app") {
            cleanName = String(cleanName.dropLast(".vercel.app".count))
        }
        
        // Split by "-" and get the last component as team
        let nameComponents = cleanName.components(separatedBy: "-")
        if nameComponents.count >= 2 {
            teamSlug = nameComponents.last
        }
        
        // Construct environment settings URL: https://vercel.com/[team]/[project]/settings/environments/[environment]
        let encodedProjectName = projectName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? projectName
        let environmentPath = environment.rawValue.lowercased()
        
        if let team = teamSlug, !team.isEmpty {
            let encodedTeam = team.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? team
            return URL(string: "https://vercel.com/\(encodedTeam)/\(encodedProjectName)/settings/environments/\(environmentPath)")
        } else {
            return URL(string: "https://vercel.com/\(encodedProjectName)/settings/environments/\(environmentPath)")
        }
    }
    
    /// Returns the logs URL for this deployment
    var logsURL: URL? {
        // Extract team from deployment name
        var teamSlug: String? = nil
        
        // Remove .vercel.app suffix if present
        var cleanName = name
        if cleanName.hasSuffix(".vercel.app") {
            cleanName = String(cleanName.dropLast(".vercel.app".count))
        }
        
        // Split by "-" and get the last component as team
        let nameComponents = cleanName.components(separatedBy: "-")
        if nameComponents.count >= 2 {
            teamSlug = nameComponents.last
        }
        
        // Construct logs URL: https://vercel.com/[team]/[project]/logs?deploymentIds=[deploymentId]
        let encodedProjectName = projectName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? projectName
        let encodedDeploymentId = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? id
        
        if let team = teamSlug, !team.isEmpty {
            let encodedTeam = team.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? team
            return URL(string: "https://vercel.com/\(encodedTeam)/\(encodedProjectName)/logs?deploymentIds=\(encodedDeploymentId)")
        } else {
            return URL(string: "https://vercel.com/\(encodedProjectName)/logs?deploymentIds=\(encodedDeploymentId)")
        }
    }
}

// MARK: - Preview Data

extension Deployment {
    static let dummyDeployments: [Deployment] = [
        Deployment(
            id: "dpl_abc123xyz456",
            name: "my-app-abc123-team.vercel.app",
            projectName: "my-app",
            domains: ["my-app.com", "www.my-app.com"],
            status: .ready,
            createdAt: Date().addingTimeInterval(-17 * 60),
            author: "developer",
            authorGithubUsername: "octocat",
            branch: "main",
            commitHash: "a1b2c3d",
            commitMessage: "Update homepage content and styling",
            buildDuration: 48,
            githubOrg: "my-org",
            githubRepo: "my-app",
            environment: .production,
            isCurrent: true,
            isPromoted: true
        ),
        Deployment(
            id: "dpl_def456",
            name: "my-app-def456-team.vercel.app",
            projectName: "my-app",
            domains: ["my-app.com"],
            status: .ready,
            createdAt: Date().addingTimeInterval(-2 * 60 * 60),
            author: "developer",
            authorGithubUsername: "octocat",
            branch: "main",
            commitHash: "e4f5g6h",
            commitMessage: "Fix calculation bug",
            buildDuration: 38,
            githubOrg: "my-org",
            githubRepo: "my-app",
            environment: .production,
            isCurrent: false,
            isPromoted: false
        ),
        Deployment(
            id: "dpl_ghi789",
            name: "my-app-ghi789-team.vercel.app",
            projectName: "my-app",
            domains: [],
            status: .building,
            createdAt: Date().addingTimeInterval(-5 * 60),
            author: "developer",
            authorGithubUsername: "octocat",
            branch: "feature/new-ui",
            commitHash: "i7j8k9l",
            commitMessage: "Add new dashboard components",
            buildDuration: nil,
            githubOrg: "my-org",
            githubRepo: "my-app",
            environment: .preview,
            isCurrent: false,
            isPromoted: false
        ),
        Deployment(
            id: "dpl_jkl012",
            name: "my-app-jkl012-team.vercel.app",
            projectName: "my-app",
            domains: [],
            status: .error,
            createdAt: Date().addingTimeInterval(-1 * 60 * 60),
            author: "developer",
            authorGithubUsername: "octocat",
            branch: "fix/api-endpoint",
            commitHash: "m0n1o2p",
            commitMessage: "Attempted fix for API timeout issues",
            buildDuration: 12,
            githubOrg: "my-org",
            githubRepo: "my-app",
            environment: .preview,
            isCurrent: false,
            isPromoted: false
        ),
        Deployment(
            id: "dpl_mno345",
            name: "my-app-mno345-team.vercel.app",
            projectName: "my-app",
            domains: ["my-app.com"],
            status: .ready,
            createdAt: Date().addingTimeInterval(-24 * 60 * 60),
            author: "developer",
            authorGithubUsername: "octocat",
            branch: "main",
            commitHash: "q3r4s5t",
            commitMessage: "Initial release v1.0.0",
            buildDuration: 52,
            githubOrg: "my-org",
            githubRepo: "my-app",
            environment: .production,
            isCurrent: false,
            isPromoted: true
        ),
        Deployment(
            id: "dpl_pqr678",
            name: "my-app-pqr678-team.vercel.app",
            projectName: "my-app",
            domains: [],
            status: .cancelled,
            createdAt: Date().addingTimeInterval(-3 * 60 * 60),
            author: "developer",
            authorGithubUsername: "octocat",
            branch: "experiment/test",
            commitHash: "u7v8w9x",
            commitMessage: "Testing new build configuration",
            buildDuration: nil,
            githubOrg: "my-org",
            githubRepo: "my-app",
            environment: .preview,
            isCurrent: false,
            isPromoted: false
        )
    ]
}

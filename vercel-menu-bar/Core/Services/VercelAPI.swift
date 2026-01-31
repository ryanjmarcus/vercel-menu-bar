//
//  VercelAPI.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import Foundation
import Combine

// MARK: - API Client

class VercelAPI: ObservableObject {
    static let shared = VercelAPI()
    
    @Published var deployments: [Deployment] = []
    @Published var projects: [VercelProject] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isLoadingProjects = false
    @Published var error: String?
    @Published var hasMoreDeployments = false
    
    private var lastDeploymentTimestamp: Int64?
    
    private let baseURL = "https://api.vercel.com"
    
    // MARK: - Fetch Projects
    
    func fetchProjects(apiKey: String) async {
        guard !apiKey.isEmpty else { return }
        
        await MainActor.run {
            self.isLoadingProjects = true
            self.error = nil
        }
        
        let urlString = "\(baseURL)/v10/projects?limit=100"
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.error = "Invalid URL"
                self.isLoadingProjects = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.error = "Invalid response from server"
                    self.isLoadingProjects = false
                }
                return
            }
            
            if httpResponse.statusCode == 401 {
                await MainActor.run {
                    self.error = "Invalid API key"
                    self.isLoadingProjects = false
                }
                return
            }
            
            if httpResponse.statusCode == 403 {
                await MainActor.run {
                    self.error = "Access forbidden - check API key permissions"
                    self.isLoadingProjects = false
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let bodyMessage = responseBody?.isEmpty == false ? " - \(responseBody!)" : ""
                await MainActor.run {
                    self.error = "HTTP error: \(httpResponse.statusCode)\(bodyMessage)"
                    self.isLoadingProjects = false
                }
                return
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(VercelProjectsResponse.self, from: data)
            
            await MainActor.run {
                self.projects = apiResponse.projects
                self.isLoadingProjects = false
                self.error = nil
            }
        } catch let decodingError as DecodingError {
            await MainActor.run {
                // Log the decoding error for debugging
                print("Decoding error: \(decodingError)")
                if case .keyNotFound(let key, let context) = decodingError {
                    print("Missing key: \(key.stringValue) at \(context.codingPath)")
                } else if case .typeMismatch(let type, let context) = decodingError {
                    print("Type mismatch: expected \(type) at \(context.codingPath)")
                }
                self.error = "Failed to decode projects response"
                self.isLoadingProjects = false
            }
        } catch let urlError as URLError {
            await MainActor.run {
                switch urlError.code {
                case .notConnectedToInternet:
                    self.error = "No internet connection"
                case .cannotFindHost, .dnsLookupFailed:
                    self.error = "Cannot reach Vercel API. Check your internet connection."
                case .timedOut:
                    self.error = "Request timed out"
                default:
                    self.error = "Network error: \(urlError.localizedDescription)"
                }
                self.isLoadingProjects = false
            }
        } catch {
            await MainActor.run {
                self.error = "Error: \(error.localizedDescription)"
                self.isLoadingProjects = false
            }
        }
    }
    
    // MARK: - Fetch Deployments
    
    func fetchDeployments(apiKey: String, projectId: String? = nil, limit: Int = 10) async {
        guard !apiKey.isEmpty else {
            await MainActor.run {
                self.error = nil
                self.deployments = []
                self.hasMoreDeployments = false
                self.lastDeploymentTimestamp = nil
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
            self.hasMoreDeployments = false
            self.lastDeploymentTimestamp = nil
        }
        
        var urlString = "\(baseURL)/v6/deployments?limit=\(limit)"
        if let projectId = projectId, !projectId.isEmpty {
            urlString += "&projectId=\(projectId)"
        }
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.error = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let bodyMessage = responseBody?.isEmpty == false ? " - \(responseBody!)" : ""
                throw APIError.httpError(httpResponse.statusCode, message: bodyMessage)
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(VercelDeploymentsResponse.self, from: data)
            
            // Capture projects for domain lookup
            let currentProjects = await MainActor.run { self.projects }
            
            let mappedDeployments = apiResponse.deployments.map { vercelDeploy -> Deployment in
                // Map state
                let status: DeploymentStatus
                switch (vercelDeploy.readyState ?? vercelDeploy.state ?? "").uppercased() {
                case "READY":
                    status = .ready
                case "BUILDING", "INITIALIZING":
                    status = .building
                case "ERROR":
                    status = .error
                case "QUEUED":
                    status = .queued
                case "CANCELED":
                    status = .cancelled
                default:
                    status = .ready
                }
                
                // Get commit info from meta
                let commitSha = vercelDeploy.meta?.githubCommitSha 
                    ?? vercelDeploy.meta?.gitlabCommitSha 
                    ?? vercelDeploy.meta?.bitbucketCommitSha 
                    ?? ""
                
                let commitMessage = vercelDeploy.meta?.githubCommitMessage 
                    ?? vercelDeploy.meta?.gitlabCommitMessage 
                    ?? vercelDeploy.meta?.bitbucketCommitMessage 
                    ?? ""
                
                let branch = vercelDeploy.meta?.githubCommitRef 
                    ?? vercelDeploy.meta?.gitlabCommitRef 
                    ?? vercelDeploy.meta?.bitbucketCommitRef 
                    ?? "main"
                
                // Get GitHub repo info
                let githubOrg = vercelDeploy.meta?.githubOrg
                let githubRepo = vercelDeploy.meta?.githubRepo
                
                // Parse created timestamp
                let createdTimestamp = vercelDeploy.createdAt ?? vercelDeploy.created ?? 0
                let createdDate = Date(timeIntervalSince1970: TimeInterval(createdTimestamp) / 1000)
                
                // Get author
                let author = vercelDeploy.creator?.username 
                    ?? vercelDeploy.creator?.githubLogin 
                    ?? vercelDeploy.creator?.email 
                    ?? "unknown"
                
                // Build deployment URL
                let deploymentUrl = vercelDeploy.url ?? "\(vercelDeploy.name).vercel.app"
                
                // Extract project name from deployment name
                let projectName = vercelDeploy.name.components(separatedBy: "-").first ?? vercelDeploy.name
                
                // Determine environment from target field
                let environment: DeploymentEnvironment
                if let target = vercelDeploy.target {
                    switch target.lowercased() {
                    case "production":
                        environment = .production
                    case "preview":
                        environment = .preview
                    default:
                        environment = .preview // Default to preview for non-production
                    }
                } else {
                    // If no target, assume preview (most deployments are previews)
                    environment = .preview
                }
                
                // For now, mark as current if it's the first deployment (we'll enhance this later)
                // In a real implementation, we'd check against the project's current production deployment
                let isCurrent = false // TODO: Check against project's current deployment
                
                // Get domains from project's latestDeployments (v6 list doesn't include alias)
                var domains: [String] = []
                if let projectId = vercelDeploy.projectId,
                   let project = currentProjects.first(where: { $0.id == projectId }),
                   let latestDeployments = project.latestDeployments,
                   let matchingDeployment = latestDeployments.first(where: { $0.deploymentId == vercelDeploy.uid }),
                   let alias = matchingDeployment.alias {
                    domains = alias
                } else if let projectId = vercelDeploy.projectId,
                          let project = currentProjects.first(where: { $0.id == projectId }),
                          let latestDeployments = project.latestDeployments,
                          let firstDeployment = latestDeployments.first,
                          let alias = firstDeployment.alias,
                          environment == .production {
                    // For production deployments, use the first latestDeployment's alias
                    domains = alias
                }
                
                let isPromoted = vercelDeploy.readySubstate == "PROMOTED"
                
                return Deployment(
                    id: vercelDeploy.uid,
                    name: deploymentUrl,
                    projectName: projectName,
                    domains: domains,
                    status: status,
                    createdAt: createdDate,
                    author: author,
                    authorGithubUsername: vercelDeploy.creator?.githubLogin,
                    branch: branch,
                    commitHash: commitSha,
                    commitMessage: commitMessage,
                    buildDuration: vercelDeploy.computedBuildDuration,
                    githubOrg: githubOrg,
                    githubRepo: githubRepo,
                    environment: environment,
                    isCurrent: isCurrent,
                    isPromoted: isPromoted
                )
            }
            
            await MainActor.run {
                self.deployments = mappedDeployments
                self.isLoading = false
                // Use pagination.next directly as the cursor for next page
                self.lastDeploymentTimestamp = apiResponse.pagination?.next
                self.hasMoreDeployments = self.lastDeploymentTimestamp != nil
            }
            
        } catch let error as APIError {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Load More Deployments
    
    func loadMoreDeployments(apiKey: String, projectId: String? = nil, limit: Int = 10) async {
        guard !apiKey.isEmpty else { return }
        
        // Use lastDeploymentTimestamp if available, otherwise compute from last deployment
        let until: Int64
        if let timestamp = lastDeploymentTimestamp {
            until = timestamp
        } else if let lastDeployment = await MainActor.run(body: { self.deployments.last }) {
            until = Int64(lastDeployment.createdAt.timeIntervalSince1970 * 1000)
        } else { return }
        
        await MainActor.run {
            self.isLoadingMore = true
        }
        
        var urlString = "\(baseURL)/v6/deployments?limit=\(limit)&until=\(until)"
        if let projectId = projectId, !projectId.isEmpty {
            urlString += "&projectId=\(projectId)"
        }
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.isLoadingMore = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.error = "Invalid response from server"
                    self.isLoadingMore = false
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let bodyMessage = responseBody?.isEmpty == false ? " - \(responseBody!)" : ""
                await MainActor.run {
                    self.error = "HTTP error: \(httpResponse.statusCode)\(bodyMessage)"
                    self.isLoadingMore = false
                }
                return
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(VercelDeploymentsResponse.self, from: data)
            
            // Capture projects for domain lookup
            let currentProjects = await MainActor.run { self.projects }
            
            let mappedDeployments = apiResponse.deployments.map { vercelDeploy -> Deployment in
                // Map state
                let status: DeploymentStatus
                switch (vercelDeploy.readyState ?? vercelDeploy.state ?? "").uppercased() {
                case "READY":
                    status = .ready
                case "BUILDING", "INITIALIZING":
                    status = .building
                case "ERROR":
                    status = .error
                case "QUEUED":
                    status = .queued
                case "CANCELED":
                    status = .cancelled
                default:
                    status = .ready
                }
                
                // Get commit info from meta
                let commitSha = vercelDeploy.meta?.githubCommitSha 
                    ?? vercelDeploy.meta?.gitlabCommitSha 
                    ?? vercelDeploy.meta?.bitbucketCommitSha 
                    ?? ""
                
                let commitMessage = vercelDeploy.meta?.githubCommitMessage 
                    ?? vercelDeploy.meta?.gitlabCommitMessage 
                    ?? vercelDeploy.meta?.bitbucketCommitMessage 
                    ?? ""
                
                let branch = vercelDeploy.meta?.githubCommitRef 
                    ?? vercelDeploy.meta?.gitlabCommitRef 
                    ?? vercelDeploy.meta?.bitbucketCommitRef 
                    ?? "main"
                
                // Get GitHub repo info
                let githubOrg = vercelDeploy.meta?.githubOrg
                let githubRepo = vercelDeploy.meta?.githubRepo
                
                // Parse created timestamp
                let createdTimestamp = vercelDeploy.createdAt ?? vercelDeploy.created ?? 0
                let createdDate = Date(timeIntervalSince1970: TimeInterval(createdTimestamp) / 1000)
                
                // Get author
                let author = vercelDeploy.creator?.username 
                    ?? vercelDeploy.creator?.githubLogin 
                    ?? vercelDeploy.creator?.email 
                    ?? "unknown"
                
                // Build deployment URL
                let deploymentUrl = vercelDeploy.url ?? "\(vercelDeploy.name).vercel.app"
                
                // Extract project name from deployment name
                let projectName = vercelDeploy.name.components(separatedBy: "-").first ?? vercelDeploy.name
                
                // Determine environment from target field
                let environment: DeploymentEnvironment
                if let target = vercelDeploy.target {
                    switch target.lowercased() {
                    case "production":
                        environment = .production
                    case "preview":
                        environment = .preview
                    default:
                        environment = .preview
                    }
                } else {
                    environment = .preview
                }
                
                // Get domains from project's latestDeployments (v6 list doesn't include alias)
                var domains: [String] = []
                if let projectId = vercelDeploy.projectId,
                   let project = currentProjects.first(where: { $0.id == projectId }),
                   let latestDeployments = project.latestDeployments,
                   let matchingDeployment = latestDeployments.first(where: { $0.deploymentId == vercelDeploy.uid }),
                   let alias = matchingDeployment.alias {
                    domains = alias
                } else if let projectId = vercelDeploy.projectId,
                          let project = currentProjects.first(where: { $0.id == projectId }),
                          let latestDeployments = project.latestDeployments,
                          let firstDeployment = latestDeployments.first,
                          let alias = firstDeployment.alias,
                          environment == .production {
                    // For production deployments, use the first latestDeployment's alias
                    domains = alias
                }
                
                let isPromoted = vercelDeploy.readySubstate == "PROMOTED"
                
                return Deployment(
                    id: vercelDeploy.uid,
                    name: deploymentUrl,
                    projectName: projectName,
                    domains: domains,
                    status: status,
                    createdAt: createdDate,
                    author: author,
                    authorGithubUsername: vercelDeploy.creator?.githubLogin,
                    branch: branch,
                    commitHash: commitSha,
                    commitMessage: commitMessage,
                    buildDuration: vercelDeploy.computedBuildDuration,
                    githubOrg: githubOrg,
                    githubRepo: githubRepo,
                    environment: environment,
                    isCurrent: false,
                    isPromoted: isPromoted
                )
            }
            
            await MainActor.run {
                // Filter out any duplicates based on deployment ID
                let existingIds = Set(self.deployments.map { $0.id })
                let newDeployments = mappedDeployments.filter { !existingIds.contains($0.id) }
                self.deployments.append(contentsOf: newDeployments)
                self.isLoadingMore = false
                // Use pagination.next directly as the cursor for next page
                self.lastDeploymentTimestamp = apiResponse.pagination?.next
                self.hasMoreDeployments = self.lastDeploymentTimestamp != nil
            }
            
        } catch {
            await MainActor.run {
                self.isLoadingMore = false
            }
        }
    }
}

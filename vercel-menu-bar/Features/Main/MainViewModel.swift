//
//  MainViewModel.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import Observation

// MARK: - View State

enum ViewState: Equatable {
    case main
    case settings(focusToken: Bool = false)
    case deploymentDetail(Deployment)
    
    static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main): return true
        case (.settings, .settings): return true
        case (.deploymentDetail(let a), .deploymentDetail(let b)): return a.id == b.id
        default: return false
        }
    }
    
    var key: String {
        switch self {
        case .main: return "main"
        case .settings: return "settings"
        case .deploymentDetail(let d): return "detail-\(d.id)"
        }
    }
}

// MARK: - Content Display State

/// Represents the possible states of the main content area
enum ContentDisplayState {
    case loading
    case noApiKey
    case invalidToken
    case noDeployments
    case hasDeployments(latest: Deployment)
    
    init(
        latestDeployment: Deployment?,
        isLoading: Bool,
        hasApiKey: Bool,
        hasSelectedProject: Bool,
        errorMessage: String?
    ) {
        if let latest = latestDeployment {
            self = .hasDeployments(latest: latest)
        } else if isLoading {
            self = .loading
        } else if !hasApiKey {
            self = .noApiKey
        } else if errorMessage != nil {
            self = .invalidToken
        } else if hasSelectedProject {
            self = .noDeployments
        } else {
            // No project selected - show nothing (empty state)
            self = .noDeployments
        }
    }
}

// MARK: - Main View Model

@Observable
final class MainViewModel {
    // MARK: - Dependencies
    
    private let api: VercelAPI
    private let settings: SettingsManager
    
    // MARK: - View State
    
    var viewState: ViewState = .main
    var recentDeploymentsToShow: Int = 5
    var refreshRotationAngle: Double = 0
    
    // MARK: - Computed Properties
    
    var latestDeployment: Deployment? {
        api.deployments.first
    }
    
    var contentState: ContentDisplayState {
        ContentDisplayState(
            latestDeployment: latestDeployment,
            isLoading: api.isLoading,
            hasApiKey: settings.hasApiKey,
            hasSelectedProject: settings.hasSelectedProject,
            errorMessage: api.error
        )
    }
    
    var currentFaviconURL: URL? {
        api.projects.first(where: { $0.id == settings.selectedProjectId })?.faviconURL ?? settings.faviconURL
    }
    
    var deployments: [Deployment] {
        api.deployments
    }
    
    var isLoading: Bool {
        api.isLoading
    }
    
    var isLoadingMore: Bool {
        api.isLoadingMore
    }
    
    var error: String? {
        api.error
    }
    
    var hasSelectedProject: Bool {
        settings.hasSelectedProject
    }
    
    var selectedProjectName: String {
        settings.selectedProjectName
    }
    
    // MARK: - Initialization
    
    init(api: VercelAPI = .shared, settings: SettingsManager = .shared) {
        self.api = api
        self.settings = settings
    }
    
    // MARK: - Actions
    
    func navigateToSettings(focusToken: Bool = false) {
        withAnimation {
            viewState = .settings(focusToken: focusToken)
        }
    }
    
    func navigateToMain() {
        withAnimation {
            viewState = .main
        }
    }
    
    func navigateToDeploymentDetail(_ deployment: Deployment) {
        withAnimation {
            viewState = .deploymentDetail(deployment)
        }
    }
    
    func showLessDeployments() {
        withAnimation {
            recentDeploymentsToShow = 5
        }
    }
    
    func refreshDeployments() {
        guard settings.hasSelectedProject else { return }
        Task {
            await api.fetchDeployments(
                apiKey: settings.apiKey,
                projectId: settings.selectedProjectId
            )
        }
    }
    
    func loadMoreDeployments() {
        Task {
            await api.loadMoreDeployments(
                apiKey: settings.apiKey,
                projectId: settings.selectedProjectId
            )
            await MainActor.run {
                recentDeploymentsToShow += 5
            }
        }
    }
    
    func loadInitialData() async {
        if settings.hasApiKey {
            if api.projects.isEmpty {
                await api.fetchProjects(apiKey: settings.apiKey)
            }
            if settings.hasSelectedProject {
                refreshDeployments()
            }
        }
    }
    
    func handleLoadingStateChange(wasLoading: Bool, isNowLoading: Bool) {
        if isNowLoading {
            refreshRotationAngle = 0
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                refreshRotationAngle = 360
            }
        } else if wasLoading {
            refreshRotationAngle = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.6)) {
                    self.refreshRotationAngle = 360
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.refreshRotationAngle = 0
                }
            }
        }
    }
}

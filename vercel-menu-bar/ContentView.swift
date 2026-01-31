//
//  ContentView.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Notification Names

extension Notification.Name {
    static let closePopover = Notification.Name("closePopover")
}

// MARK: - Main Menu Bar View

struct MenuBarView: View {
    @StateObject private var api = VercelAPI.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var viewState: ViewState = .main
    @State private var recentDeploymentsToShow: Int = 5
    @State private var refreshRotationAngle: Double = 0
    @State private var refreshAnimationId: UUID = UUID()
    @State private var refreshTimer: Timer?
    
    var latestDeployment: Deployment? {
        api.deployments.first
    }
    
    var body: some View {
        ZStack {
            Color.vercelBackground
                .ignoresSafeArea()
            
            switch viewState {
            case .main:
                mainView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .settings(let focusToken):
                SettingsView(
                    onBack: {
                        withAnimation {
                            viewState = .main
                        }
                    },
                    onSave: {
                        refreshDeployments()
                    },
                    focusTokenInput: focusToken
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .deploymentDetail(let deployment):
                DeploymentDetailView(
                    deployment: deployment,
                    onBack: {
                        withAnimation {
                            viewState = .main
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 380, height: 556)
        .animation(.easeInOut(duration: 0.2), value: viewStateKey)
        .onChange(of: api.isLoading) { oldValue, newValue in
            if newValue {
                // Start continuous rotation when loading begins
                refreshRotationAngle = 0
                refreshAnimationId = UUID()
                // Start continuous rotation animation
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    refreshRotationAngle = 360
                }
            } else if oldValue == true {
                // When loading completes, trigger one-time refresh animation
                // Force stop the continuous animation by changing the ID
                refreshAnimationId = UUID()
                // Reset to 0 immediately to stop the continuous animation
                refreshRotationAngle = 0
                
                // Trigger completion animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        self.refreshRotationAngle = 360
                    }
                    // Reset after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        self.refreshRotationAngle = 0
                    }
                }
            }
        }
        .task {
            if settings.hasApiKey {
                // Fetch projects if we have an API key (needed for favicon)
                if api.projects.isEmpty {
                    await api.fetchProjects(apiKey: settings.apiKey)
                }
                // Fetch deployments if we have a selected project
                if settings.hasSelectedProject {
                    refreshDeployments()
                }
            }
        }
        .onChange(of: settings.refreshIntervalSeconds) { _, _ in
            setupAutoRefresh()
        }
        .onChange(of: settings.fastRefreshEnabled) { _, _ in
            setupAutoRefresh()
        }
        .onChange(of: settings.fastRefreshIntervalSeconds) { _, _ in
            setupAutoRefresh()
        }
        .onChange(of: api.deployments) { _, _ in
            setupAutoRefresh()
        }
        .onAppear {
            setupAutoRefresh()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
    
    private var viewStateKey: String {
        switch viewState {
        case .main: return "main"
        case .settings: return "settings"
        case .deploymentDetail(let d): return "detail-\(d.id)"
        }
    }
    
    private func refreshDeployments() {
        guard settings.hasSelectedProject else { return }
        Task {
            await api.fetchDeployments(
                apiKey: settings.apiKey,
                projectId: settings.selectedProjectId
            )
        }
    }
    
    private func setupAutoRefresh() {
        // Cancel existing timer
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        // Don't set up auto-refresh if no project is selected
        guard settings.hasSelectedProject else { return }
        
        // Determine which interval to use
        let hasBuildingDeployment = api.deployments.contains { $0.status == .building }
        let shouldUseFastRefresh = hasBuildingDeployment && settings.fastRefreshEnabled
        
        let intervalSeconds: Int
        if shouldUseFastRefresh {
            intervalSeconds = settings.fastRefreshIntervalSeconds
        } else {
            intervalSeconds = settings.refreshIntervalSeconds
        }
        
        // Don't set up timer if interval is 0 or negative
        guard intervalSeconds > 0 else { return }
        
        // Capture values we need
        let apiKey = settings.apiKey
        let projectId = settings.selectedProjectId
        
        // Set up new timer on main thread
        Task { @MainActor in
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalSeconds), repeats: true) { _ in
                // Only refresh if not already loading
                if !VercelAPI.shared.isLoading {
                    Task {
                        await VercelAPI.shared.fetchDeployments(
                            apiKey: apiKey,
                            projectId: projectId
                        )
                    }
                }
            }
            // Add timer to common run loop modes so it works when menu is open
            RunLoop.main.add(timer, forMode: .common)
            refreshTimer = timer
        }
    }
    
    // MARK: - Content State
    
    private var contentState: ContentDisplayState {
        ContentDisplayState(
            latestDeployment: latestDeployment,
            isLoading: api.isLoading,
            hasApiKey: settings.hasApiKey,
            hasSelectedProject: settings.hasSelectedProject,
            errorMessage: api.error
        )
    }
    
    private var currentFaviconURL: URL? {
        api.projects.first(where: { $0.id == settings.selectedProjectId })?.faviconURL ?? settings.faviconURL
    }
    
    // MARK: - Main View
    
    private var mainView: some View {
        VStack(spacing: 0) {
            // Header
            MainHeader(
                hasSelectedProject: settings.hasSelectedProject,
                projectName: settings.selectedProjectName,
                faviconURL: currentFaviconURL,
                isLoading: api.isLoading,
                refreshRotationAngle: refreshRotationAngle,
                onRefresh: refreshDeployments,
                onSettings: { withAnimation { viewState = .settings() } },
                onClose: {
                    NotificationCenter.default.post(name: .closePopover, object: nil)
                }
            )
            
            // Error banner
            if let error = api.error {
                ErrorBanner(error, actionTitle: "Settings") {
                    withAnimation { viewState = .settings() }
                }
            }
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Content based on state
                    ContentStateView(
                        state: contentState,
                        project: api.projects.first(where: { $0.id == settings.selectedProjectId }),
                        onNavigateToSettings: { withAnimation { viewState = .settings(focusToken: true) } },
                        onRefresh: refreshDeployments
                    )
                    
                    // Recent Deployments
                    RecentDeploymentsSection(
                        deployments: api.deployments,
                        deploymentsToShow: recentDeploymentsToShow,
                        isLoadingMore: api.isLoadingMore,
                        onDeploymentTap: { deployment in
                            withAnimation { viewState = .deploymentDetail(deployment) }
                        },
                        onShowLess: {
                            withAnimation { recentDeploymentsToShow = 5 }
                        },
                        onLoadMore: {
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
                    )
                }
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    MenuBarView()
        .frame(width: 380, height: 556)
}

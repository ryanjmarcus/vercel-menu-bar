//
//  ContentStateView.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI

// MARK: - Content State View

/// Renders the appropriate view for the current content state
struct ContentStateView: View {
    let state: ContentDisplayState
    let project: VercelProject?
    let onNavigateToSettings: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        switch state {
        case .loading:
            LoadingView("Loading deployments...")
            
        case .noApiKey:
            EmptyStateView(
                icon: "key.fill",
                title: "Connect to Vercel",
                message: "Add your API token to view your deployments",
                buttonTitle: "Add Token",
                action: onNavigateToSettings
            )
            .padding(.top, 40)
            
        case .invalidToken:
            EmptyStateView(
                icon: "key.fill",
                title: "Token Error",
                message: "Please update your token to view deployments",
                buttonTitle: "Update Token",
                action: onNavigateToSettings
            )
            .padding(.top, 40)
            
        case .noDeployments:
            EmptyStateView(
                icon: "cube.box",
                title: "No Deployments",
                message: "No deployments found for this project",
                buttonTitle: "Refresh",
                action: onRefresh
            )
            .padding(.top, 40)
            
        case .hasDeployments(let latest):
            OverviewSection(deployment: latest, project: project)
        }
    }
}

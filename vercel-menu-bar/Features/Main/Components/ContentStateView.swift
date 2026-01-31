//
//  ContentStateView.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
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
            
        case .noProject:
            EmptyStateView(
                icon: "folder",
                title: "Select a Project",
                message: "Choose a project to view its deployments",
                buttonTitle: "Select Project",
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

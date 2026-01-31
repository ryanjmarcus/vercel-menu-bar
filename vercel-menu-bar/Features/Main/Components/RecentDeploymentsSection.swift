//
//  RecentDeploymentsSection.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI

// MARK: - Recent Deployments Section

/// The section showing recent deployments with load more functionality
struct RecentDeploymentsSection: View {
    let deployments: [Deployment]
    let deploymentsToShow: Int
    let isLoadingMore: Bool
    let onDeploymentTap: (Deployment) -> Void
    let onShowLess: () -> Void
    let onLoadMore: () -> Void
    
    private var recentDeployments: [Deployment] {
        Array(deployments.dropFirst().prefix(deploymentsToShow))
    }
    
    var body: some View {
        if deployments.count > 1 {
            VStack(spacing: 10) {
                // Deployments list
                DeploymentsList(
                    deployments: recentDeployments,
                    showLessAction: deploymentsToShow > 5 ? onShowLess : nil,
                    onDeploymentTap: onDeploymentTap
                )
                
                // Load More Button
                LoadMoreButton(
                    isLoading: isLoadingMore,
                    action: onLoadMore
                )
            }
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - Deployments List

/// A list of deployment rows in a card container
struct DeploymentsList: View {
    let deployments: [Deployment]
    let showLessAction: (() -> Void)?
    let onDeploymentTap: (Deployment) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(
                title: "Recent Deployments",
                action: showLessAction,
                actionLabel: showLessAction != nil ? "Show Less" : nil
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .fill(Color.vercelBorder)
                .frame(height: 1)
            
            ForEach(Array(deployments.enumerated()), id: \.element.id) { index, deployment in
                DeploymentRow(deployment: deployment) {
                    onDeploymentTap(deployment)
                }
                
                if index < deployments.count - 1 {
                    Rectangle()
                        .fill(Color.vercelBorder)
                        .frame(height: 1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.vercelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.vercelBorder, lineWidth: 1)
        )
    }
}

// MARK: - Load More Button

/// A button to load more deployments
struct LoadMoreButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.5)
                        .frame(width: 14, height: 14)
                }
                Text(isLoading ? "Loading..." : "Load More")
                    .font(.vercelBody)
                    .foregroundColor(.vercelPrimaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.vercelBackground)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.vercelBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .pointerOnHover(disabled: isLoading)
    }
}

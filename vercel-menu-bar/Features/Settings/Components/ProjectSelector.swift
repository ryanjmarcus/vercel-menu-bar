//
//  ProjectSelector.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI

// MARK: - Project Selector Content

/// The content of the project selector dropdown
struct ProjectSelectorContent: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var api: VercelAPI
    @Binding var isExpanded: Bool
    let isValidating: Bool
    let onProjectSelect: (VercelProject) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if settings.hasApiKey && !isValidating {
                if api.projects.isEmpty {
                    LoadProjectsButton(apiKey: settings.apiKey, api: api)
                        .padding(12)
                } else {
                    ProjectDropdown(
                        settings: settings,
                        projects: api.projects,
                        isExpanded: $isExpanded,
                        onSelect: onProjectSelect
                    )
                }
            } else {
                LockedPlaceholder(message: "Add an API token to select a project")
            }
        }
        .background(Color.vercelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.vercelBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

// MARK: - Load Projects Button

struct LoadProjectsButton: View {
    let apiKey: String
    @ObservedObject var api: VercelAPI
    
    var body: some View {
        Button(action: {
            Task {
                await api.fetchProjects(apiKey: apiKey)
            }
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                Text("Load Projects")
                    .font(.vercelBody)
            }
            .foregroundColor(.vercelPrimaryText)
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
        .pointerOnHover()
    }
}

// MARK: - Project Dropdown

struct ProjectDropdown: View {
    @ObservedObject var settings: SettingsManager
    let projects: [VercelProject]
    @Binding var isExpanded: Bool
    let onSelect: (VercelProject) -> Void
    
    private var selectedProject: VercelProject? {
        projects.first { $0.id == settings.selectedProjectId }
    }
    
    private var otherProjects: [VercelProject] {
        projects.filter { $0.id != settings.selectedProjectId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Current selection (always visible)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    if let selectedProject = selectedProject {
                        ProjectFavicon(url: selectedProject.faviconURL)
                        Text(selectedProject.name)
                            .font(.vercelBody)
                            .foregroundColor(.vercelPrimaryText)
                    } else {
                        VercelTriangleIcon()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.vercelSecondaryText)
                        Text("Select a project...")
                            .font(.vercelBody)
                            .foregroundColor(.vercelSecondaryText)
                    }
                    
                    Spacer()
                    
                    if settings.hasSelectedProject {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.vercelPrimaryText)
                    }
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.vercelSecondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointerOnHover()
            
            // Expanded project list
            if isExpanded {
                Divider()
                    .background(Color.vercelBorder.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(otherProjects.enumerated()), id: \.element.id) { index, project in
                            ProjectListItem(
                                project: project,
                                isSelected: false,
                                onSelect: {
                                    onSelect(project)
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        isExpanded = false
                                    }
                                }
                            )
                            
                            if index < otherProjects.count - 1 {
                                Divider()
                                    .background(Color.vercelBorder.opacity(0.3))
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
    }
}

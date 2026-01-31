//
//  SettingsView.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var api = VercelAPI.shared
    @State private var apiKeyInput: String = ""
    @State private var isKeyVisible: Bool = false
    @State private var isValidating: Bool = false
    @State private var isProjectDropdownExpanded: Bool = false
    
    let onBack: () -> Void
    let onSave: () -> Void
    
    private let refreshIntervalOptions = [10, 15, 30, 60]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            NavigationHeader(onBack: onBack, title: "Settings")
            
            ScrollView {
                VStack(spacing: 16) {
                    // Project Selector Section
                    projectSection
                    
                    // API Key Section
                    apiKeySection
                    
                    // Refresh Section
                    refreshSection
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
        .background(Color.vercelBackground)
        .onAppear {
            apiKeyInput = settings.apiKey
            if settings.hasApiKey && api.projects.isEmpty {
                Task {
                    await api.fetchProjects(apiKey: settings.apiKey)
                }
            }
        }
    }
    
    // MARK: - Project Section
    
    private var projectSection: some View {
        SettingsSection(title: "Project", subtitle: "Select a project to view its deployments") {
            Spacer()
                .frame(height: 12)
            
            ProjectSelectorContent(
                settings: settings,
                api: api,
                isExpanded: $isProjectDropdownExpanded,
                isValidating: isValidating,
                onProjectSelect: { project in
                    settings.selectProject(project)
                    onSave()
                }
            )
        }
    }
    
    // MARK: - Refresh Section
    
    private var refreshSection: some View {
        SettingsSection(title: "Refresh", subtitle: "Control how often deployments update") {
            VStack(alignment: .leading, spacing: 12) {
                SettingRow(title: "Base interval", description: "Default poll rate") {
                    IntervalSelector(
                        options: refreshIntervalOptions,
                        selectedSeconds: settings.refreshIntervalSeconds,
                        onSelect: { interval in
                            settings.refreshIntervalSeconds = interval
                            onSave()
                        }
                    )
                }
                
                SettingRow(title: "Active deployments", description: "While builds are in progress") {
                    ActiveIntervalSelector(settings: settings, onSave: onSave)
                }
            }
            .padding(12)
        }
    }
    
    // MARK: - API Key Section
    
    private var apiKeySection: some View {
        SettingsSection(
            title: "Vercel API Token",
            subtitleView: { APITokenLink() }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // API Key Input Row
                HStack(spacing: 8) {
                    // Input field
                    apiKeyInputField
                    
                    // Action buttons
                    IconActionButton(systemName: "doc.on.clipboard") {
                        if let pasteboardString = NSPasteboard.general.string(forType: .string) {
                            apiKeyInput = pasteboardString
                        }
                    }
                    
                    IconActionButton(systemName: isKeyVisible ? "eye.slash" : "eye") {
                        isKeyVisible.toggle()
                    }
                    
                    if settings.hasApiKey {
                        IconActionButton(systemName: "trash") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                apiKeyInput = ""
                                settings.apiKey = ""
                                settings.selectedProjectId = ""
                                settings.selectedProjectName = ""
                                settings.selectedProjectFaviconURL = ""
                                api.projects = []
                                api.deployments = []
                            }
                            onSave()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: settings.hasApiKey)
                
                // Save Button
                saveTokenButton
            }
            .padding(12)
        }
    }
    
    private var apiKeyInputField: some View {
        TextFieldWithShortcuts(
            isKeyVisible ? "Enter your Vercel API token" : "Enter your API token...",
            text: $apiKeyInput,
            isSecure: !isKeyVisible
        )
        .frame(height: 18)
        .padding(10)
        .background(Color.vercelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.vercelBorder, lineWidth: 1)
        )
    }
    
    private var saveTokenButton: some View {
        Button(action: saveToken) {
            HStack(spacing: 6) {
                if isValidating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                }
                
                Text(isValidating ? "Saving token..." : "Save Token")
                    .font(.vercelBody)
            }
            .foregroundColor(.vercelPrimaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 18)
            .padding(10)
            .background(Color.vercelBackground)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.vercelBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isValidating)
        .pointerOnHover(disabled: isValidating)
    }
    
    private func saveToken() {
        guard !isValidating else { return }
        
        isValidating = true
        settings.apiKey = apiKeyInput
        
        Task {
            await api.fetchProjects(apiKey: apiKeyInput)
            
            await MainActor.run {
                isValidating = false
                
                // Auto-select first project if none is selected
                if !settings.hasSelectedProject, let firstProject = api.projects.first {
                    settings.selectProject(firstProject)
                }
                
                onSave()
            }
        }
    }
}

#Preview {
    SettingsView(onBack: {}, onSave: {})
        .frame(width: 380, height: 520)
}

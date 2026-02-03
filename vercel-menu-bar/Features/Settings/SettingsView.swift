//
//  SettingsView.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var api = VercelAPI.shared
    @ObservedObject var updaterManager = UpdaterManager.shared
    @State private var apiKeyInput: String = ""
    @State private var isKeyVisible: Bool = false
    @State private var isValidating: Bool = false
    @State private var isProjectDropdownExpanded: Bool = false
    @State private var hasAppliedInitialFocus: Bool = false
    @State private var isGitHubHovered: Bool = false
    @State private var isUpdateHovered: Bool = false
    @State private var showHomebrewPopover: Bool = false
    @State private var copiedToClipboard: Bool = false
    
    let onBack: () -> Void
    let onSave: () -> Void
    var focusTokenInput: Bool = false
    
    private let refreshIntervalOptions = [5, 10, 15, 30]
    
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
                    
                    // General Section
                    generalSection
                    
                    // Footer
                    aboutFooter
                }
                .padding(.top, 12)
                .padding(.bottom, 14)
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
    
    // MARK: - About Footer
    
    private var aboutFooter: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        return HStack(spacing: 0) {
            Button(action: {
                if let url = URL(string: "https://github.com/ryanjmarcus/vercel-menu-bar") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Text("GitHub")
                    .font(.system(size: 11))
                    .underline(isGitHubHovered)
                    .foregroundColor(isGitHubHovered ? .vercelSecondaryTextHover : .vercelSecondaryText.opacity(0.5))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isGitHubHovered = hovering
                }
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Text("  ·  v\(version)  ·  ")
                .font(.system(size: 11))
                .foregroundColor(.vercelSecondaryText.opacity(0.5))
            
            Button(action: {
                if updaterManager.isHomebrewInstall && updaterManager.updateAvailable {
                    showHomebrewPopover = true
                } else {
                    updaterManager.checkForUpdates()
                }
            }) {
                HStack(spacing: 4) {
                    if updaterManager.updateAvailable {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    Text(updaterManager.updateAvailable ? "Update Available" : "Check for Updates")
                        .font(.system(size: 11))
                        .underline(isUpdateHovered)
                }
                .foregroundColor(isUpdateHovered ? .vercelSecondaryTextHover : .vercelSecondaryText.opacity(0.5))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isUpdateHovered = hovering
                }
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .popover(isPresented: $showHomebrewPopover, arrowEdge: .top) {
                homebrewUpdatePopover
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }
    
    // MARK: - Homebrew Update Popover
    
    private var homebrewUpdatePopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update via Homebrew")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.vercelPrimaryText)
            
            Text("This app was installed via Homebrew. Run this command to update:")
                .font(.system(size: 11))
                .foregroundColor(.vercelSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 8) {
                Text(UpdaterManager.brewUpdateCommand)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.vercelPrimaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.vercelBackground)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.vercelBorder, lineWidth: 1)
                    )
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(UpdaterManager.brewUpdateCommand, forType: .string)
                    copiedToClipboard = true
                    
                    // Reset after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedToClipboard = false
                    }
                }) {
                    Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.clipboard")
                        .font(.system(size: 12))
                        .foregroundColor(copiedToClipboard ? .green : .vercelSecondaryText)
                        .frame(width: 32, height: 32)
                        .background(Color.vercelCardBackground)
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
        .padding(14)
        .frame(width: 300)
        .background(Color.vercelCardBackground)
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
    
    // MARK: - General Section
    
    private var generalSection: some View {
        SettingsSection(title: "General", subtitle: "App behavior settings") {
            VStack(alignment: .leading, spacing: 12) {
                // Launch at Login
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at login")
                            .font(.vercelBody)
                            .foregroundColor(.vercelPrimaryText)
                        Text("Start automatically when you log in")
                            .font(.vercelCaption)
                            .foregroundColor(.vercelSecondaryText)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { settings.launchAtLogin },
                        set: { settings.launchAtLogin = $0 }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .pointerOnHover()
                }
                
                // Window Size
                SettingRow(title: "Window size", description: "Height of the popover") {
                    WindowSizeSelector(
                        selectedSize: settings.windowSize,
                        onSelect: { settings.windowSize = $0 }
                    )
                }
            }
            .padding(12)
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
                    
                    // Only show eye icon if token hasn't been saved yet, or if user is editing
                    if !settings.hasApiKey || apiKeyInput != settings.apiKey {
                        IconActionButton(systemName: isKeyVisible ? "eye.slash" : "eye") {
                            isKeyVisible.toggle()
                        }
                    }
                    
                    if settings.hasApiKey {
                        IconActionButton(systemName: "trash", isDestructive: true) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                apiKeyInput = ""
                                settings.apiKey = ""
                                settings.selectedProjectId = ""
                                settings.selectedProjectName = ""
                                settings.selectedProjectFaviconURL = ""
                                api.projects = []
                                api.deployments = []
                                api.error = nil // Clear any error when token is removed
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
        ZStack(alignment: .trailing) {
            TextFieldWithShortcuts(
                isKeyVisible ? "Enter your Vercel API token" : "Enter your API token",
                text: $apiKeyInput,
                isSecure: !isKeyVisible,
                shouldFocus: focusTokenInput && !hasAppliedInitialFocus
            )
            .id("apiKeyInput-\(isKeyVisible)") // Force recreate when visibility toggles
            .frame(height: 18)
            .padding(10)
            .padding(.trailing, showErrorIcon ? 24 : 0) // Add padding when error icon is shown
            .background(Color.vercelBackground)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(showErrorIcon ? Color.red.opacity(0.4) : Color.vercelBorder, lineWidth: 1)
            )
            .onAppear {
                if focusTokenInput && !hasAppliedInitialFocus {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        hasAppliedInitialFocus = true
                    }
                }
            }
            
            // Error icon
            if showErrorIcon {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.trailing, 10)
            }
        }
    }
    
    private var showErrorIcon: Bool {
        settings.hasApiKey && api.error != nil
    }
    
    private var saveTokenButton: some View {
        HoverableButton(action: saveToken, disabled: isValidating) {
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
        }
        .disabled(isValidating)
        .pointerOnHover(disabled: isValidating)
    }
    
    private func saveToken() {
        guard !isValidating else { return }
        
        isValidating = true
        
        // Clear error if token is empty
        if apiKeyInput.isEmpty {
            settings.apiKey = ""
            api.error = nil
            api.projects = []
            api.deployments = []
            isValidating = false
            onSave()
            return
        }
        
        Task {
            // If this is the first time saving a token, request keychain access first
            let hasSavedBefore = UserDefaults.standard.bool(forKey: "has_saved_token_before")
            if !hasSavedBefore {
                let accessGranted = KeychainManager.shared.requestAccess(forKey: "vercel_api_key")
                
                await MainActor.run {
                    if !accessGranted {
                        // User denied keychain access
                        isValidating = false
                        // Optionally show an error message here
                        return
                    }
                }
            }
            
            // Now save the token (this will trigger keychain save)
            await MainActor.run {
                settings.apiKey = apiKeyInput
            }
            
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
        .frame(width: 380, height: 556)
}

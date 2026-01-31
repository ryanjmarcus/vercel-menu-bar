//
//  SettingsViewModel.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit
import Observation

// MARK: - Settings View Model

@Observable
final class SettingsViewModel {
    // MARK: - Dependencies
    
    private let api: VercelAPI
    private let settings: SettingsManager
    
    // MARK: - UI State
    
    var apiKeyInput: String = ""
    var isKeyVisible: Bool = false
    var isValidating: Bool = false
    var isProjectDropdownExpanded: Bool = false
    
    // MARK: - Constants
    
    let refreshIntervalOptions = [5, 10, 15, 30]
    
    // MARK: - Computed Properties
    
    var projects: [VercelProject] {
        api.projects
    }
    
    var hasApiKey: Bool {
        settings.hasApiKey
    }
    
    var hasSelectedProject: Bool {
        settings.hasSelectedProject
    }
    
    var selectedProjectId: String {
        settings.selectedProjectId
    }
    
    var refreshIntervalSeconds: Int {
        get { settings.refreshIntervalSeconds }
        set { settings.refreshIntervalSeconds = newValue }
    }
    
    var fastRefreshEnabled: Bool {
        get { settings.fastRefreshEnabled }
        set { settings.fastRefreshEnabled = newValue }
    }
    
    var fastRefreshIntervalSeconds: Int {
        get { settings.fastRefreshIntervalSeconds }
        set { settings.fastRefreshIntervalSeconds = newValue }
    }
    
    // MARK: - Initialization
    
    init(api: VercelAPI = .shared, settings: SettingsManager = .shared) {
        self.api = api
        self.settings = settings
        self.apiKeyInput = settings.apiKey
    }
    
    // MARK: - Actions
    
    func onAppear() {
        apiKeyInput = settings.apiKey
        if settings.hasApiKey && api.projects.isEmpty {
            Task {
                await api.fetchProjects(apiKey: settings.apiKey)
            }
        }
    }
    
    func selectProject(_ project: VercelProject) {
        settings.selectProject(project)
        withAnimation(.easeInOut(duration: 0.15)) {
            isProjectDropdownExpanded = false
        }
    }
    
    func toggleProjectDropdown() {
        withAnimation(.easeInOut(duration: 0.15)) {
            isProjectDropdownExpanded.toggle()
        }
    }
    
    func setRefreshInterval(_ interval: Int) {
        settings.refreshIntervalSeconds = interval
    }
    
    func setFastRefresh(enabled: Bool, seconds: Int? = nil) {
        if let seconds = seconds {
            settings.fastRefreshEnabled = true
            settings.fastRefreshIntervalSeconds = seconds
        } else {
            settings.fastRefreshEnabled = false
        }
    }
    
    func pasteFromClipboard() {
        if let pasteboardString = NSPasteboard.general.string(forType: .string) {
            apiKeyInput = pasteboardString
        }
    }
    
    func toggleKeyVisibility() {
        isKeyVisible.toggle()
    }
    
    func clearToken() {
        withAnimation(.easeInOut(duration: 0.2)) {
            apiKeyInput = ""
            settings.apiKey = ""
            settings.selectedProjectId = ""
            settings.selectedProjectName = ""
            settings.selectedProjectFaviconURL = ""
            api.projects = []
            api.deployments = []
        }
    }
    
    func saveToken() async {
        guard !isValidating else { return }
        
        await MainActor.run {
            isValidating = true
        }
        
        settings.apiKey = apiKeyInput
        await api.fetchProjects(apiKey: apiKeyInput)
        
        await MainActor.run {
            isValidating = false
            
            // Auto-select first project if none is selected
            if !settings.hasSelectedProject, let firstProject = api.projects.first {
                settings.selectProject(firstProject)
            }
        }
    }
    
    func loadProjects() {
        Task {
            await api.fetchProjects(apiKey: settings.apiKey)
        }
    }
}

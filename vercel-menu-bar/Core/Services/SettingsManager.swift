//
//  SettingsManager.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import Foundation
import Combine

// MARK: - Settings Storage

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let apiKeyKey = "vercel_api_key"
    private let projectIdKey = "vercel_project_id"
    private let projectNameKey = "vercel_project_name"
    private let projectFaviconKey = "vercel_project_favicon"
    private let refreshIntervalKey = "refresh_interval_seconds"
    private let fastRefreshEnabledKey = "refresh_fast_enabled"
    private let fastRefreshIntervalKey = "refresh_fast_interval_seconds"
    
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
        }
    }
    
    @Published var selectedProjectId: String {
        didSet {
            UserDefaults.standard.set(selectedProjectId, forKey: projectIdKey)
        }
    }
    
    @Published var selectedProjectName: String {
        didSet {
            UserDefaults.standard.set(selectedProjectName, forKey: projectNameKey)
        }
    }
    
    @Published var selectedProjectFaviconURL: String {
        didSet {
            UserDefaults.standard.set(selectedProjectFaviconURL, forKey: projectFaviconKey)
        }
    }

    @Published var refreshIntervalSeconds: Int {
        didSet {
            UserDefaults.standard.set(refreshIntervalSeconds, forKey: refreshIntervalKey)
        }
    }

    @Published var fastRefreshEnabled: Bool {
        didSet {
            UserDefaults.standard.set(fastRefreshEnabled, forKey: fastRefreshEnabledKey)
        }
    }

    @Published var fastRefreshIntervalSeconds: Int {
        didSet {
            UserDefaults.standard.set(fastRefreshIntervalSeconds, forKey: fastRefreshIntervalKey)
        }
    }
    
    init() {
        self.apiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
        self.selectedProjectId = UserDefaults.standard.string(forKey: projectIdKey) ?? ""
        self.selectedProjectName = UserDefaults.standard.string(forKey: projectNameKey) ?? ""
        self.selectedProjectFaviconURL = UserDefaults.standard.string(forKey: projectFaviconKey) ?? ""

        let storedRefreshInterval = UserDefaults.standard.integer(forKey: refreshIntervalKey)
        self.refreshIntervalSeconds = storedRefreshInterval > 0 ? storedRefreshInterval : 15

        if UserDefaults.standard.object(forKey: fastRefreshEnabledKey) == nil {
            self.fastRefreshEnabled = true
        } else {
            self.fastRefreshEnabled = UserDefaults.standard.bool(forKey: fastRefreshEnabledKey)
        }

        let storedFastInterval = UserDefaults.standard.integer(forKey: fastRefreshIntervalKey)
        self.fastRefreshIntervalSeconds = storedFastInterval > 0 ? storedFastInterval : 5
    }
    
    var hasApiKey: Bool {
        !apiKey.isEmpty
    }
    
    var hasSelectedProject: Bool {
        !selectedProjectId.isEmpty
    }
    
    var faviconURL: URL? {
        guard !selectedProjectFaviconURL.isEmpty else { return nil }
        return URL(string: selectedProjectFaviconURL)
    }
    
    func selectProject(_ project: VercelProject) {
        selectedProjectId = project.id
        selectedProjectName = project.name
        selectedProjectFaviconURL = project.faviconURL?.absoluteString ?? ""
    }
}

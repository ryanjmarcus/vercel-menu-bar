//
//  SettingsManager.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import Foundation
import Combine
import ServiceManagement

// MARK: - Window Size

enum WindowSize: String, CaseIterable {
    case compact = "compact"
    case `default` = "default"
    case tall = "tall"
    
    var height: CGFloat {
        switch self {
        case .compact: return 452
        case .default: return 556
        case .tall: return 700
        }
    }
    
    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .default: return "Default"
        case .tall: return "Tall"
        }
    }
}

// MARK: - Settings Storage

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let apiKeyKey = "vercel_api_key"
    private let hasSavedTokenKey = "has_saved_token_before"
    private let projectIdKey = "vercel_project_id"
    private let projectNameKey = "vercel_project_name"
    private let projectFaviconKey = "vercel_project_favicon"
    private let refreshIntervalKey = "refresh_interval_seconds"
    private let fastRefreshEnabledKey = "refresh_fast_enabled"
    private let fastRefreshIntervalKey = "refresh_fast_interval_seconds"
    private let windowSizeKey = "window_size"
    
    @Published var apiKey: String {
        didSet {
            if apiKey.isEmpty {
                _ = KeychainManager.shared.delete(forKey: apiKeyKey)
                UserDefaults.standard.set(false, forKey: hasSavedTokenKey)
            } else {
                _ = KeychainManager.shared.save(apiKey, forKey: apiKeyKey)
                UserDefaults.standard.set(true, forKey: hasSavedTokenKey)
            }
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
    
    @Published var windowSize: WindowSize {
        didSet {
            UserDefaults.standard.set(windowSize.rawValue, forKey: windowSizeKey)
        }
    }
    
    init() {
        // Only try to load from keychain if we've saved a token before
        // This prevents keychain access prompt on first launch
        let hasSavedBefore = UserDefaults.standard.bool(forKey: hasSavedTokenKey)
        
        if hasSavedBefore {
            // Load API key from keychain (user has already granted access)
            self.apiKey = KeychainManager.shared.get(forKey: apiKeyKey) ?? ""
        } else {
            // First launch - don't touch keychain at all
            self.apiKey = ""
        }
        
        self.selectedProjectId = UserDefaults.standard.string(forKey: projectIdKey) ?? ""
        self.selectedProjectName = UserDefaults.standard.string(forKey: projectNameKey) ?? ""
        self.selectedProjectFaviconURL = UserDefaults.standard.string(forKey: projectFaviconKey) ?? ""

        let storedRefreshInterval = UserDefaults.standard.integer(forKey: refreshIntervalKey)
        self.refreshIntervalSeconds = storedRefreshInterval > 0 ? storedRefreshInterval : 10

        if UserDefaults.standard.object(forKey: fastRefreshEnabledKey) == nil {
            self.fastRefreshEnabled = true
        } else {
            self.fastRefreshEnabled = UserDefaults.standard.bool(forKey: fastRefreshEnabledKey)
        }

        let storedFastInterval = UserDefaults.standard.integer(forKey: fastRefreshIntervalKey)
        self.fastRefreshIntervalSeconds = storedFastInterval > 0 ? storedFastInterval : 5
        
        if let storedWindowSize = UserDefaults.standard.string(forKey: windowSizeKey),
           let size = WindowSize(rawValue: storedWindowSize) {
            self.windowSize = size
        } else {
            self.windowSize = .default
        }
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
    
    // MARK: - Launch at Login
    
    var launchAtLogin: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            objectWillChange.send()
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
}

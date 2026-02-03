//
//  UpdaterManager.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import Foundation
import Combine
import Sparkle

// MARK: - Updater Manager

final class UpdaterManager: NSObject, ObservableObject, SPUUpdaterDelegate {
    static let shared = UpdaterManager()
    
    private var updater: SPUUpdater!
    private var userDriver: SPUStandardUserDriver!
    
    @Published var updateAvailable = false
    @Published var canCheckForUpdates = false
    
    /// Whether the app was installed via Homebrew Cask
    let isHomebrewInstall: Bool
    
    /// The brew command to update the app
    static let brewUpdateCommand = "brew upgrade --cask vercel-menu-bar"
    
    private var cancellables = Set<AnyCancellable>()
    private var lastCheckTime: Date?
    private let checkCooldown: TimeInterval = 3600  // 1 hour
    
    private override init() {
        // Detect Homebrew install before calling super.init()
        self.isHomebrewInstall = Self.detectHomebrewInstall()
        
        super.init()
        
        // Create user driver and updater with self as delegate
        userDriver = SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil)
        updater = SPUUpdater(
            hostBundle: Bundle.main,
            applicationBundle: Bundle.main,
            userDriver: userDriver,
            delegate: self
        )
        
        // Observe canCheckForUpdates
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
        
        // Start the updater
        do {
            try updater.start()
        } catch {
            print("Failed to start Sparkle updater: \(error)")
        }
    }
    
    /// Called when popover opens - checks with 1-hour cooldown
    func checkForUpdateIfNeeded() {
        let now = Date()
        if let lastCheck = lastCheckTime, now.timeIntervalSince(lastCheck) < checkCooldown {
            return  // Skip - checked recently
        }
        lastCheckTime = now
        checkForUpdateInformation()
    }
    
    /// User-initiated check (opens Sparkle UI)
    func checkForUpdates() {
        updater.checkForUpdates()
    }
    
    /// Silent probe - delegate methods will be called
    private func checkForUpdateInformation() {
        updater.checkForUpdateInformation()
    }
    
    // MARK: - SPUUpdaterDelegate
    
    func feedURLString(for updater: SPUUpdater) -> String? {
        return "https://ryanjmarcus.github.io/vercel-menu-bar/appcast.xml"
    }
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        DispatchQueue.main.async {
            self.updateAvailable = true
        }
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        DispatchQueue.main.async {
            self.updateAvailable = false
        }
    }
    
    // MARK: - Homebrew Detection
    
    /// Detects if the app was installed via Homebrew Cask
    private static func detectHomebrewInstall() -> Bool {
        let appPath = Bundle.main.bundlePath
        
        // Check if running directly from Homebrew's Caskroom
        if appPath.contains("/Caskroom/") || appPath.contains("/homebrew/") {
            return true
        }
        
        // Check if /Applications/Vercel Menu Bar.app is a symlink to Homebrew
        let applicationsPath = "/Applications/Vercel Menu Bar.app"
        let fm = FileManager.default
        
        // Check if the path is a symlink
        guard let attrs = try? fm.attributesOfItem(atPath: applicationsPath),
              let fileType = attrs[.type] as? FileAttributeType,
              fileType == .typeSymbolicLink else {
            return false
        }
        
        // Check if symlink points to Homebrew
        if let destination = try? fm.destinationOfSymbolicLink(atPath: applicationsPath) {
            return destination.contains("Caskroom") || destination.contains("homebrew")
        }
        
        return false
    }
}

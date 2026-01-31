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
    
    private var cancellables = Set<AnyCancellable>()
    private var lastCheckTime: Date?
    private let checkCooldown: TimeInterval = 3600  // 1 hour
    
    private override init() {
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
}

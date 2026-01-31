//
//  vercel_menuApp.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import SwiftUI
import AppKit
import Combine

@main
struct vercel_menuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate for Edit Menu Support

class AppDelegate: NSObject, NSApplicationDelegate {
    private let api = VercelAPI.shared
    private let settings = SettingsManager.shared
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create Edit menu for keyboard shortcuts (Cmd+V, Cmd+C, etc.)
        setupEditMenu()
        setupStatusItem()
        observeStatusUpdates()
    }
    
    private func setupEditMenu() {
        let editMenu = NSMenu(title: "Edit")
        
        let cutItem = NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        let copyItem = NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        let pasteItem = NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        editMenu.addItem(cutItem)
        editMenu.addItem(copyItem)
        editMenu.addItem(pasteItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(selectAllItem)
        
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu
        
        // Insert Edit menu after the app menu
        if NSApp.mainMenu == nil {
            NSApp.mainMenu = NSMenu()
        }
        
        if let mainMenu = NSApp.mainMenu {
            // Add Edit menu if it doesn't exist
            if mainMenu.item(withTitle: "Edit") == nil {
                if mainMenu.items.count > 0 {
                    mainMenu.insertItem(editMenuItem, at: 1)
                } else {
                    mainMenu.addItem(editMenuItem)
                }
            }
        }
    }
    
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        
        if let button = item.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 520)
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        
        updateStatusItemImage()
    }
    
    private func observeStatusUpdates() {
        api.$deployments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemImage()
            }
            .store(in: &cancellables)
        
        settings.$apiKey
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemImage()
            }
            .store(in: &cancellables)
        
        settings.$selectedProjectId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemImage()
            }
            .store(in: &cancellables)
    }
    
    private func updateStatusItemImage() {
        // Only show status badge if user has token and project selected
        let status: DeploymentStatus?
        if settings.hasApiKey && settings.hasSelectedProject {
            status = api.deployments.first?.status ?? .ready
        } else {
            status = nil // Show plain icon without badge
        }
        
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let iconView = MenuBarIconView(status: status)
            .environment(\.colorScheme, isDarkMode ? .dark : .light)
        let renderer = ImageRenderer(content: iconView)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        
        if let image = renderer.nsImage {
            image.isTemplate = false
            statusItem?.button?.image = image
        }
    }
    
    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

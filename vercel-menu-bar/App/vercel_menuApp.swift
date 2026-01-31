//
//  vercel_menuApp.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit
import Combine
import Sparkle

@main
struct vercel_menuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - Status Bar Button View

class StatusBarButtonView: NSView {
    var rightClickMenu: NSMenu?
    
    override func mouseDown(with event: NSEvent) {
        // Forward left-clicks to the button behind us
        if let button = superview as? NSButton {
            button.mouseDown(with: event)
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if let menu = rightClickMenu {
            menu.popUp(positioning: nil, at: NSPoint(x: bounds.minX, y: bounds.maxY), in: nil)
        } else {
            super.rightMouseDown(with: event)
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
    
    // Sparkle updater controller for automatic updates
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle updater for automatic updates
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        // Create Edit menu for keyboard shortcuts (Cmd+V, Cmd+C, etc.)
        setupEditMenu()
        setupStatusItem()
        observeStatusUpdates()
        observePopoverClose()
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
        
        guard let button = item.button else { return }
        
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: .leftMouseDown)
        
        // Create custom view for right-click menu support
        let customView = StatusBarButtonView()
        customView.frame = button.bounds
        customView.autoresizingMask = [.width, .height]
        
        // Add right-click menu with Quit option
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        customView.rightClickMenu = menu
        
        // Add custom view as subview to handle right-clicks
        // Make it non-interactive for left-clicks so they pass through to button
        customView.wantsLayer = false
        button.addSubview(customView)
        
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 556)
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
    
    @MainActor private func updateStatusItemImage() {
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
    
    private func observePopoverClose() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: .closePopover,
            object: nil
        )
    }
    
    @objc private func closePopover() {
        popover.performClose(nil)
    }
    
    @objc private func quitApp(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
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

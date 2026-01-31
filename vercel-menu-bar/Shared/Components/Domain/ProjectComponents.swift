//
//  ProjectComponents.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Favicon Image Cache

/// Global image cache that persists across view recreations
final class FaviconCache {
    static let shared = FaviconCache()
    
    private let cache = NSCache<NSURL, NSImage>()
    
    private init() {
        cache.countLimit = 50 // Max 50 images
    }
    
    func get(_ url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func set(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

// MARK: - Async Favicon

/// A unified favicon component that loads images asynchronously with caching
struct AsyncFavicon: View {
    let url: URL?
    let size: CGFloat
    let cornerRadius: CGFloat
    let showFallback: Bool
    
    @State private var displayImage: NSImage?
    
    /// Creates an async favicon with configurable size
    /// - Parameters:
    ///   - url: The URL of the favicon to load
    ///   - size: The size of the favicon (default: 20)
    ///   - cornerRadius: The corner radius (default: 4)
    ///   - showFallback: Whether to show the triangle fallback when no image (default: true)
    init(url: URL?, size: CGFloat = 20, cornerRadius: CGFloat = 4, showFallback: Bool = true) {
        self.url = url
        self.size = size
        self.cornerRadius = cornerRadius
        self.showFallback = showFallback
    }
    
    var body: some View {
        // Absolutely fixed-size container using min/max constraints
        faviconContent
            .frame(minWidth: size, maxWidth: size, minHeight: size, maxHeight: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                loadFromCache()
            }
            .task(id: url) {
                await loadImage()
            }
    }
    
    @ViewBuilder
    private var faviconContent: some View {
        if let image = displayImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if showFallback {
            VercelTriangleIcon()
                .foregroundColor(.vercelSecondaryText)
        } else {
            // Invisible rectangle that takes up exact space
            Rectangle()
                .fill(Color.clear)
        }
    }
    
    /// Load from cache immediately on appear (synchronous, no flicker)
    private func loadFromCache() {
        guard let url = url else { return }
        if let cached = FaviconCache.shared.get(url) {
            displayImage = cached
        }
    }
    
    /// Load image from network (async)
    private func loadImage() async {
        guard let url = url else {
            displayImage = nil
            return
        }
        
        // Check cache first
        if let cached = FaviconCache.shared.get(url) {
            displayImage = cached
            return
        }
        
        // Fetch from network
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP status code - only accept 200 responses
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }
            
            // Try to create an NSImage
            if data.count > 0, let image = NSImage(data: data), image.size.width > 0, image.size.height > 0 {
                // Cache it
                FaviconCache.shared.set(image, for: url)
                displayImage = image
            }
        } catch {
            // Silently fail - keep showing whatever we have (cached or triangle)
        }
    }
}

// MARK: - Convenience Aliases

/// Favicon for project headers (16x16, corner radius 3, no fallback during loading)
struct ProjectHeaderFavicon: View {
    let url: URL?
    
    var body: some View {
        AsyncFavicon(url: url, size: 16, cornerRadius: 3, showFallback: false)
    }
}

/// Favicon for project list items (20x20, corner radius 4)
struct ProjectFavicon: View {
    let url: URL?
    
    var body: some View {
        AsyncFavicon(url: url, size: 20, cornerRadius: 4)
    }
}

// MARK: - Project List Item

struct ProjectListItem: View {
    let project: VercelProject
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                ProjectFavicon(url: project.faviconURL)
                
                Text(project.name)
                    .font(.vercelBody)
                    .foregroundColor(.vercelPrimaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.vercelPrimaryText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(isHovered ? Color.vercelHover : Color.clear)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Vercel Triangle Icon

struct VercelTriangleIcon: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let scale = size / 16.0
            Path { path in
                // SVG coordinates scaled: top (8,2), bottom right (15,14.5), bottom left (1,14.5)
                path.move(to: CGPoint(x: 8 * scale, y: 2 * scale))
                path.addLine(to: CGPoint(x: 15 * scale, y: 14.5 * scale))
                path.addLine(to: CGPoint(x: 1 * scale, y: 14.5 * scale))
                path.closeSubpath()
            }
            .stroke(style: StrokeStyle(lineWidth: max(0.5, 1.25 * scale), dash: [max(0.5, 1.25 * scale), max(0.5, 1.25 * scale)]))
            .foregroundColor(.vercelSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

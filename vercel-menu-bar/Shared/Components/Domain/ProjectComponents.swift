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
    
    /// Token that changes when failures should be retried
    private(set) var refreshToken: UUID = UUID()
    
    private init() {
        cache.countLimit = 50 // Max 50 images
    }
    
    func get(_ url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func set(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
    
    /// Call to force all favicons to retry loading (e.g., after deployment refresh)
    func invalidateFailures() {
        refreshToken = UUID()
    }
}

// MARK: - Async Favicon

/// Load state for favicon fetching
private enum FaviconLoadState {
    case idle       // Not yet attempted
    case loading    // Fetch in progress
    case loaded     // Successfully loaded image
    case failed     // Fetch failed (404, error, etc.)
}

/// A unified favicon component that loads images asynchronously with caching
struct AsyncFavicon: View {
    let url: URL?
    let size: CGFloat
    let cornerRadius: CGFloat
    let showFallback: Bool
    
    @State private var displayImage: NSImage?
    @State private var loadState: FaviconLoadState = .idle
    
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
            .onChange(of: url) { oldURL, newURL in
                // Reset state when URL changes to prevent showing stale image
                if oldURL != newURL {
                    displayImage = nil
                    loadState = .idle
                    // Load from cache for new URL immediately
                    if let newURL = newURL {
                        if let cached = FaviconCache.shared.get(newURL) {
                            displayImage = cached
                            loadState = .loaded
                        }
                    }
                }
            }
            .task(id: taskId) {
                await loadImage()
            }
    }
    
    /// Combine url + refreshToken so task re-runs on refresh
    private var taskId: String {
        "\(url?.absoluteString ?? "")-\(FaviconCache.shared.refreshToken)"
    }
    
    @ViewBuilder
    private var faviconContent: some View {
        if let image = displayImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if showFallback || loadState == .failed {
            // Show fallback if explicitly requested OR if load failed
            VercelTriangleIcon()
                .foregroundColor(.vercelSecondaryText)
        } else {
            // Loading in progress - invisible space to prevent flicker
            Rectangle()
                .fill(Color.clear)
        }
    }
    
    /// Load from cache immediately on appear (synchronous, no flicker)
    private func loadFromCache() {
        guard let url = url else { return }
        if let cached = FaviconCache.shared.get(url) {
            displayImage = cached
            loadState = .loaded
        }
    }
    
    /// Load image from network (async)
    private func loadImage() async {
        guard let url = url else {
            loadState = .failed
            displayImage = nil
            return
        }
        
        // Check cache first
        if let cached = FaviconCache.shared.get(url) {
            loadState = .loaded
            displayImage = cached
            return
        }
        
        // Reset to loading state at start of each network fetch attempt
        // This ensures retries (via refreshToken change) start fresh
        loadState = .loading
        
        // Fetch from network with browser-like headers
        // Vercel's API may require User-Agent to serve favicons
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP status code - only accept 200 responses
            guard let httpResponse = response as? HTTPURLResponse else {
                loadState = .failed
                return
            }
            
            // For 404s, retry once after a delay (favicon might take a few seconds to generate)
            if httpResponse.statusCode == 404 {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                
                let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
                if let retryHttpResponse = retryResponse as? HTTPURLResponse,
                   retryHttpResponse.statusCode == 200,
                   retryData.count > 0,
                   let retryImage = NSImage(data: retryData),
                   retryImage.size.width > 0, retryImage.size.height > 0 {
                    FaviconCache.shared.set(retryImage, for: url)
                    loadState = .loaded
                    displayImage = retryImage
                    return
                }
            }
            
            guard httpResponse.statusCode == 200,
                  data.count > 0,
                  let image = NSImage(data: data),
                  image.size.width > 0, image.size.height > 0 else {
                loadState = .failed
                return
            }
            
            FaviconCache.shared.set(image, for: url)
            loadState = .loaded
            displayImage = image
        } catch {
            loadState = .failed
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

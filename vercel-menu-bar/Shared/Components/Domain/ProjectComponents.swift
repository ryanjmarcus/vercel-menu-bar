//
//  ProjectComponents.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import SwiftUI
import AppKit

// MARK: - Async Favicon

/// A unified favicon component that loads images asynchronously
struct AsyncFavicon: View {
    let url: URL?
    let size: CGFloat
    let cornerRadius: CGFloat
    
    @State private var loadedImage: NSImage?
    
    /// Creates an async favicon with configurable size
    /// - Parameters:
    ///   - url: The URL of the favicon to load
    ///   - size: The size of the favicon (default: 20)
    ///   - cornerRadius: The corner radius (default: 4)
    init(url: URL?, size: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.url = url
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                VercelTriangleIcon()
                    .foregroundColor(.vercelSecondaryText)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(cornerRadius)
        .task(id: url) {
            loadedImage = nil
            
            guard let url = url else { return }
            
            // Try to load the image
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Simply try to create an NSImage - if it works, use it
                if data.count > 0, let image = NSImage(data: data), image.size.width > 0, image.size.height > 0 {
                    loadedImage = image
                }
            } catch {
                // Silently fail and show default icon
            }
        }
    }
}

// MARK: - Convenience Aliases

/// Favicon for project headers (16x16, corner radius 3)
struct ProjectHeaderFavicon: View {
    let url: URL?
    
    var body: some View {
        AsyncFavicon(url: url, size: 16, cornerRadius: 3)
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

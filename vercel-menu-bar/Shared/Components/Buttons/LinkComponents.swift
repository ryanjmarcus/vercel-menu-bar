//
//  LinkComponents.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - External Link Button

/// A button that opens an external URL with an arrow icon
struct ExternalLinkButton: View {
    let title: String
    let url: URL?
    let style: Style
    
    @State private var isHovered = false
    
    enum Style {
        case bordered
        case plain
    }
    
    init(_ title: String, url: URL?, style: Style = .bordered) {
        self.title = title
        self.url = url
        self.style = style
    }
    
    init(_ title: String, urlString: String, style: Style = .bordered) {
        self.title = title
        self.url = URL(string: urlString)
        self.style = style
    }
    
    var body: some View {
        Button(action: {
            if let url = url {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.vercelCaption)
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 9))
            }
            .foregroundColor(style == .bordered ? .vercelPrimaryText : .vercelSecondaryText)
            .modifier(BorderedButtonStyle(enabled: style == .bordered, isHovered: isHovered))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Bordered Button Style Modifier

private struct BorderedButtonStyle: ViewModifier {
    let enabled: Bool
    let isHovered: Bool
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isHovered ? Color.vercelHover : Color.vercelBackground)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.vercelBorder, lineWidth: 1)
                )
        } else {
            content
        }
    }
}

// MARK: - Domain Link Button

/// A button that opens a domain URL with an arrow icon
struct DomainLinkButton: View {
    let domain: String
    let showIcon: Bool
    
    init(_ domain: String, showIcon: Bool = true) {
        self.domain = domain
        self.showIcon = showIcon
    }
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://\(domain)") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 4) {
                Text(domain)
                    .font(.vercelBody)
                    .foregroundColor(.vercelPrimaryText)
                    .lineLimit(1)
                
                if showIcon {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 9))
                        .foregroundColor(.vercelSecondaryText)
                }
            }
        }
        .buttonStyle(.plain)
        .pointerOnHover()
    }
}

// MARK: - Copy Button

/// A button that copies text to the clipboard
struct CopyButton: View {
    let text: String
    let iconSize: CGFloat
    
    init(_ text: String, iconSize: CGFloat = 10) {
        self.text = text
        self.iconSize = iconSize
    }
    
    var body: some View {
        Button(action: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: iconSize))
                .foregroundColor(.vercelSecondaryText)
        }
        .buttonStyle(.plain)
        .pointerOnHover()
    }
}

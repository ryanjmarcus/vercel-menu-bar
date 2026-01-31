    //
//  LinkComponents.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI
import AppKit

// MARK: - External Link Button

/// A button that opens an external URL with an arrow icon
struct ExternalLinkButton: View {
    let title: String
    let url: URL?
    let style: Style
    
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
            .modifier(BorderedButtonStyle(enabled: style == .bordered))
        }
        .buttonStyle(.plain)
        .pointerOnHover()
    }
}

// MARK: - Bordered Button Style Modifier

private struct BorderedButtonStyle: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.vercelBackground)
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

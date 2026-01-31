//
//  SectionComponents.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI

// MARK: - Settings Section

/// A reusable container for settings sections with title, subtitle, and content
struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let subtitleView: AnyView?
    @ViewBuilder let content: Content
    
    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleView = nil
        self.content = content()
    }
    
    init(
        title: String,
        @ViewBuilder subtitleView: () -> some View,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = nil
        self.subtitleView = AnyView(subtitleView())
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.vercelHeading)
                    .foregroundColor(.vercelPrimaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.vercelCaption)
                        .foregroundColor(.vercelSecondaryText)
                } else if let subtitleView = subtitleView {
                    subtitleView
                }
            }
            .padding(12)
            
            Divider()
                .background(Color.vercelBorder.opacity(0.3))
            
            content
        }
        .background(Color.vercelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.vercelBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
    }
}

// MARK: - Card Container

/// A simple card container with Vercel styling
struct CardContainer<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .background(Color.vercelBackground)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.vercelBorder, lineWidth: 1)
            )
    }
}

// MARK: - Inner Card

/// A card container for use inside sections (with inner border styling)
struct InnerCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(Color.vercelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.vercelBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

// MARK: - Segment Control

/// A segmented control with Vercel styling
struct SegmentedControl<T: Hashable>: View {
    let options: [T]
    let selection: T
    let label: (T) -> String
    let onSelect: (T) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isSelected = selection == option
                
                Button(action: {
                    onSelect(option)
                }) {
                    Text(label(option))
                        .font(.vercelBody)
                        .foregroundColor(isSelected ? .vercelPrimaryText : .vercelSecondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(minWidth: 36)
                        .background(isSelected ? Color.vercelHover : Color.vercelBackground)
                }
                .buttonStyle(.plain)
                .pointerOnHover()
                
                if index < options.count - 1 {
                    Divider()
                        .background(Color.vercelBorder)
                }
            }
        }
        .background(Color.vercelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.vercelBorder, lineWidth: 1)
        )
        .fixedSize()
    }
}

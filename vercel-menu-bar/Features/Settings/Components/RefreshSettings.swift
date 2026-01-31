//
//  RefreshSettings.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Active Interval Selector

/// A segmented control for selecting active deployment refresh intervals
struct ActiveIntervalSelector: View {
    @ObservedObject var settings: SettingsManager
    let onSave: () -> Void
    
    private let options: [(label: String, seconds: Int?)] = [
        ("Same", nil),
        ("3s", 3),
        ("5s", 5),
        ("10s", 10)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isSelected = option.seconds == nil
                    ? !settings.fastRefreshEnabled
                    : settings.fastRefreshEnabled && settings.fastRefreshIntervalSeconds == option.seconds
                
                ActiveIntervalOption(
                    label: option.label,
                    isSelected: isSelected,
                    onSelect: {
                        if let seconds = option.seconds {
                            settings.fastRefreshEnabled = true
                            settings.fastRefreshIntervalSeconds = seconds
                        } else {
                            settings.fastRefreshEnabled = false
                        }
                        onSave()
                    }
                )
                
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

// MARK: - Active Interval Option

private struct ActiveIntervalOption: View {
    let label: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            Text(label)
                .font(.vercelBody)
                .foregroundColor(isSelected ? .vercelPrimaryText : .vercelSecondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(minWidth: 36)
                .background(backgroundColor)
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
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.vercelHover
        }
        if isHovered {
            return Color.vercelHover.opacity(0.5)
        }
        return Color.vercelBackground
    }
}

//
//  IntervalSelector.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Interval Selector

/// A segmented control for selecting time intervals
struct IntervalSelector: View {
    let options: [Int]
    let selectedSeconds: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                IntervalOption(
                    option: option,
                    isSelected: selectedSeconds == option,
                    onSelect: { onSelect(option) }
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

// MARK: - Interval Option

private struct IntervalOption: View {
    let option: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            Text("\(option)s")
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

// MARK: - Window Size Selector

/// A segmented control for selecting window size presets
struct WindowSizeSelector: View {
    let selectedSize: WindowSize
    let onSelect: (WindowSize) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(WindowSize.allCases.enumerated()), id: \.offset) { index, size in
                WindowSizeOption(
                    size: size,
                    isSelected: selectedSize == size,
                    onSelect: { onSelect(size) }
                )
                
                if index < WindowSize.allCases.count - 1 {
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

// MARK: - Window Size Option

private struct WindowSizeOption: View {
    let size: WindowSize
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            Text(size.displayName)
                .font(.vercelBody)
                .foregroundColor(isSelected ? .vercelPrimaryText : .vercelSecondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(minWidth: 50)
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

//
//  RefreshSettings.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI

// MARK: - Active Interval Selector

/// A segmented control for selecting active deployment refresh intervals
struct ActiveIntervalSelector: View {
    @ObservedObject var settings: SettingsManager
    let onSave: () -> Void
    
    private let options: [(label: String, seconds: Int?)] = [
        ("Off", nil),
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
                
                Button(action: {
                    if let seconds = option.seconds {
                        settings.fastRefreshEnabled = true
                        settings.fastRefreshIntervalSeconds = seconds
                    } else {
                        settings.fastRefreshEnabled = false
                    }
                    onSave()
                }) {
                    Text(option.label)
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

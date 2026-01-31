//
//  IntervalSelector.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI

// MARK: - Interval Selector

/// A segmented control for selecting time intervals
struct IntervalSelector: View {
    let options: [Int]
    let selectedSeconds: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isSelected = selectedSeconds == option
                
                Button(action: {
                    onSelect(option)
                }) {
                    Text("\(option)s")
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

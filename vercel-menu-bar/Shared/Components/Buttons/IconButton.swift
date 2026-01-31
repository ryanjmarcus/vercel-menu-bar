//
//  IconButton.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI

// MARK: - Icon Action Button

/// A small icon button with border styling
struct IconActionButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundColor(.vercelSecondaryText)
                .frame(width: 16, height: 16)
                .frame(width: 32, height: 32)
                .background(Color.vercelBackground)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.vercelBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .fixedSize()
        .pointerOnHover()
    }
}

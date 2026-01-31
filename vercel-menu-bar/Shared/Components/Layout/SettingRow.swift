//
//  SettingRow.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI

// MARK: - Setting Row

/// A row with label, description, and trailing control
struct SettingRow<Control: View>: View {
    let title: String
    let description: String
    @ViewBuilder let control: Control
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.vercelBody)
                    .foregroundColor(.vercelPrimaryText)
                Text(description)
                    .font(.vercelCaption)
                    .foregroundColor(.vercelSecondaryText)
            }
            
            Spacer()
            
            control
        }
    }
}

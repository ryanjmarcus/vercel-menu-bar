//
//  SettingRow.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
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

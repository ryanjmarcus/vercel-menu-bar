//
//  APIKeyInput.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - API Token Link

/// A link to the Vercel account tokens page
struct APITokenLink: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Create a token in the ")
                .font(.vercelCaption)
                .foregroundColor(.vercelSecondaryText)
            
            Button(action: {
                if let url = URL(string: "https://vercel.com/account/tokens") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 3) {
                    Text("Account Tokens Page")
                        .font(.vercelCaption)
                        .underline()
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 8))
                }
                .foregroundColor(.vercelSecondaryText)
            }
            .buttonStyle(.plain)
            .pointerOnHover()
        }
    }
}

// MARK: - Locked Placeholder

/// A placeholder shown when API key is required
struct LockedPlaceholder: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(.vercelTertiaryText)
                .frame(width: 20, height: 20)
            
            Text(message)
                .font(.vercelBody)
                .foregroundColor(.vercelTertiaryText)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

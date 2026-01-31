//
//  MenuBarComponents.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI

// MARK: - Menu Bar Status Badge

/// A small status badge with a knockout ring for native menu bar appearance
struct MenuBarStatusBadge: View {
    let status: DeploymentStatus
    
    /// Dot size (status color)
    private let dotSize: CGFloat = 5.5
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: dotSize, height: dotSize)
    }
}

// MARK: - Menu Bar Cutout Ring

struct MenuBarCutoutRing: View {
    /// Cutout ring size (slightly larger than dot)
    private let cutoutSize: CGFloat
    
    init(dotSize: CGFloat, extra: CGFloat = 1.5) {
        self.cutoutSize = dotSize + extra
    }
    
    var body: some View {
        Circle()
            .frame(width: cutoutSize, height: cutoutSize)
    }
}

// MARK: - Menu Bar Icon View

struct MenuBarIconView: View {
    let status: DeploymentStatus?
    
    private let dotSize: CGFloat = 5.5
    private let badgeOffset = CGSize(width: 0, height: 0)
    
    var body: some View {
        if let status = status {
            // Show icon with status badge
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .overlay(
                        MenuBarCutoutRing(dotSize: dotSize)
                            .offset(badgeOffset)
                            .blendMode(.destinationOut),
                        alignment: .bottomTrailing
                    )
                    .compositingGroup()
                
                MenuBarStatusBadge(status: status)
                    .frame(width: dotSize, height: dotSize)
                    .offset(badgeOffset)
            }
            .drawingGroup()
        } else {
            // Show plain icon without badge
            Image(systemName: "triangle.fill")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white)
        }
    }
}

#Preview("MenuBar Icon") {
    VStack(spacing: 16) {
        ZStack {
            Color.black.opacity(0.15)
                .frame(width: 60, height: 24)
            
            MenuBarIconView(status: .ready)
        }
        .padding(8)
        
        ZStack {
            Color.black.opacity(0.15)
                .frame(width: 60, height: 24)
            
            MenuBarIconView(status: nil)
        }
        .padding(8)
    }
}

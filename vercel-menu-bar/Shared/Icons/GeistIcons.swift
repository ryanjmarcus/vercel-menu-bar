//
//  GeistIcons.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
//

import SwiftUI

// MARK: - Git Branch Icon

struct GitBranchIcon: View {
    var size: CGFloat = 16
    var color: Color = .vercelSecondaryText
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0
            
            // Main vertical line (from top to bottom circle)
            var linePath = Path()
            linePath.move(to: CGPoint(x: 4 * scale, y: 1.5 * scale))
            linePath.addLine(to: CGPoint(x: 4 * scale, y: 10 * scale))
            context.stroke(linePath, with: .color(color), lineWidth: 1.5 * scale)
            
            // Bottom circle (larger)
            let bottomCircle = Path(ellipseIn: CGRect(
                x: 2 * scale,
                y: 10 * scale,
                width: 4 * scale,
                height: 4 * scale
            ))
            context.stroke(bottomCircle, with: .color(color), lineWidth: 1.5 * scale)
            
            // Top right circle
            let topRightCircle = Path(ellipseIn: CGRect(
                x: 10 * scale,
                y: 2 * scale,
                width: 4 * scale,
                height: 4 * scale
            ))
            context.stroke(topRightCircle, with: .color(color), lineWidth: 1.5 * scale)
            
            // Curved branch line from top-right circle to main line
            var branchPath = Path()
            branchPath.move(to: CGPoint(x: 10 * scale, y: 4 * scale))
            branchPath.addQuadCurve(
                to: CGPoint(x: 4 * scale, y: 9 * scale),
                control: CGPoint(x: 4 * scale, y: 4 * scale)
            )
            context.stroke(branchPath, with: .color(color), lineWidth: 1.5 * scale)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Git Commit Icon

struct GitCommitIcon: View {
    var size: CGFloat = 16
    var color: Color = .vercelSecondaryText
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0
            let centerY = 8 * scale
            let circleRadius = 3 * scale
            let centerX = 8 * scale
            
            // Left line
            var leftLine = Path()
            leftLine.move(to: CGPoint(x: 1 * scale, y: centerY))
            leftLine.addLine(to: CGPoint(x: centerX - circleRadius - 0.5 * scale, y: centerY))
            context.stroke(leftLine, with: .color(color), lineWidth: 1.5 * scale)
            
            // Center circle
            let circle = Path(ellipseIn: CGRect(
                x: centerX - circleRadius,
                y: centerY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
            context.stroke(circle, with: .color(color), lineWidth: 1.5 * scale)
            
            // Right line
            var rightLine = Path()
            rightLine.move(to: CGPoint(x: centerX + circleRadius + 0.5 * scale, y: centerY))
            rightLine.addLine(to: CGPoint(x: 15 * scale, y: centerY))
            context.stroke(rightLine, with: .color(color), lineWidth: 1.5 * scale)
        }
        .frame(width: size, height: size)
    }
}

#Preview("Git Icons") {
    HStack(spacing: 20) {
        VStack {
            GitBranchIcon(size: 16)
            Text("Branch")
                .font(.caption)
        }
        VStack {
            GitCommitIcon(size: 16)
            Text("Commit")
                .font(.caption)
        }
    }
    .padding()
    .background(Color.black)
    .foregroundColor(.white)
}

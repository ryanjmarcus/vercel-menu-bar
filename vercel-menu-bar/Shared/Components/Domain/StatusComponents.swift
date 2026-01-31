//
//  StatusComponents.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI

// MARK: - Status Dot

struct StatusDot: View {
    let status: DeploymentStatus
    var size: CGFloat = 8.5
    var animated: Bool = false
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
    }
}

// MARK: - Current Badge

struct CurrentBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.up")
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Current")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Color(hex: "0070f3"))
        .cornerRadius(12)
    }
}

// MARK: - Author Avatar

/// A circular avatar that fetches the GitHub profile picture
struct AuthorAvatar: View {
    let deployment: Deployment
    var size: CGFloat = 14
    
    private var githubAvatarURL: URL? {
        guard let githubUsername = deployment.authorGithubUsername else { return nil }
        return URL(string: "https://github.com/\(githubUsername).png")
    }
    
    var body: some View {
        AsyncImage(url: githubAvatarURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            case .failure(_), .empty:
                fallbackAvatar
            @unknown default:
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
    }
    
    private var fallbackAvatar: some View {
        Circle()
            .fill(Color.vercelBorder)
            .frame(width: size, height: size)
            .overlay(
                Text(String(deployment.author.prefix(1)).uppercased())
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundColor(.vercelSecondaryText)
            )
    }
}

// MARK: - Geist Spinner

/// A Geist-style spinner using native ProgressView (radial lines)
struct GeistSpinner: View {
    let size: CGFloat
    
    init(size: CGFloat = 11) {
        self.size = size
    }
    
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .controlSize(.mini)
            .scaleEffect(size / 14) // Mini size is ~14pt
            .frame(width: size, height: size)
    }
}

// MARK: - Live Duration View

/// Shows build duration - either a static completed duration or a live counter for in-progress builds
struct LiveDurationView: View {
    let deployment: Deployment
    let showIcon: Bool
    let font: Font
    let color: Color
    
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    
    init(
        deployment: Deployment,
        showIcon: Bool = false,
        font: Font = .vercelBody,
        color: Color = .vercelPrimaryText
    ) {
        self.deployment = deployment
        self.showIcon = showIcon
        self.font = font
        self.color = color
    }
    
    private var isBuilding: Bool {
        deployment.status == .building || deployment.status == .queued
    }
    
    var body: some View {
        HStack(spacing: 3) {
            if showIcon {
                if isBuilding {
                    // Show spinner when building
                    GeistSpinner(size: 16)
                } else {
                    // Show clock icon when completed
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.vercelSecondaryText)
                }
            }
            
            if let duration = deployment.buildDuration {
                // Completed build - show final duration
                Text("\(Int(duration))s")
                    .font(font)
                    .foregroundColor(color)
            } else if isBuilding {
                // Building - show live counter
                Text("\(elapsedSeconds)s")
                    .font(font)
                    .foregroundColor(color)
            }
        }
        .onAppear {
            if isBuilding {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: deployment.status) { _, newStatus in
            if newStatus == .building || newStatus == .queued {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    private func startTimer() {
        // Calculate initial elapsed time
        updateElapsedTime()
        
        // Start timer to update every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        let elapsed = Date().timeIntervalSince(deployment.createdAt)
        elapsedSeconds = max(0, Int(elapsed))
    }
}

// MARK: - Previews

#Preview("Geist Spinner") {
    VStack(spacing: 20) {
        // Different sizes
        HStack(spacing: 30) {
            VStack {
                GeistSpinner(size: 11)
                Text("11pt").font(.caption)
            }
            VStack {
                GeistSpinner(size: 16)
                Text("16pt").font(.caption)
            }
            VStack {
                GeistSpinner(size: 24)
                Text("24pt").font(.caption)
            }
            VStack {
                GeistSpinner(size: 32)
                Text("32pt").font(.caption)
            }
        }
        
        Divider()
        
        // With duration text (building state)
        VStack(alignment: .leading, spacing: 12) {
            Text("Building (with spinner):").font(.headline)
            
            HStack(spacing: 4) {
                GeistSpinner(size: 11)
                Text("42s")
                    .font(.vercelBody)
                    .foregroundColor(.vercelPrimaryText)
            }
            
            // Full LiveDurationView with building deployment
            LiveDurationView(
                deployment: Deployment.dummyDeployments[2], // Building deployment
                showIcon: true,
                font: .vercelBody,
                color: .vercelPrimaryText
            )
        }
        
        Divider()
        
        // Completed state (with clock icon)
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed (with clock):").font(.headline)
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(.vercelSecondaryText)
                Text("48s")
                    .font(.vercelBody)
                    .foregroundColor(.vercelPrimaryText)
            }
            
            // Full LiveDurationView with completed deployment
            LiveDurationView(
                deployment: Deployment.dummyDeployments[0], // Ready deployment
                showIcon: true,
                font: .vercelBody,
                color: .vercelPrimaryText
            )
        }
    }
    .padding(30)
    .background(Color.vercelBackground)
}

//
//  DomainComponents.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Domains Section

/// A section displaying all domains for a deployment with expand/collapse functionality
struct DomainsSection: View {
    let deployment: Deployment
    @State private var showAllDomains = false
    
    // Categorize domains
    private var commitDomain: String {
        deployment.name
    }
    
    private var branchDomain: String? {
        deployment.domains.first { $0.contains("-git-\(deployment.branch)-") }
    }
    
    private var mainDomain: String? {
        deployment.domains.first { !$0.hasSuffix(".vercel.app") }
    }
    
    private var additionalDomains: [String] {
        deployment.domains.filter { domain in
            domain != branchDomain &&
            domain != mainDomain &&
            domain != commitDomain
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Domains")
                .font(.vercelCaption)
                .foregroundColor(.vercelSecondaryText)
            
            VStack(alignment: .leading, spacing: 4) {
                // Main domain row with all domains in horizontal scroll
                if let mainDomain = mainDomain {
                    MainDomainRow(
                        mainDomain: mainDomain,
                        additionalDomains: additionalDomains,
                        showAllDomains: $showAllDomains
                    )
                }
                
                // Branch domain
                if let branchDomain = branchDomain {
                    DomainRowItem(
                        icon: GitBranchIcon(size: 11, color: .vercelSecondaryText),
                        domain: branchDomain
                    )
                }
                
                // Commit domain (deployment URL)
                DomainRowItem(
                    icon: GitCommitIcon(size: 11, color: .vercelSecondaryText),
                    domain: commitDomain
                )
            }
        }
    }
}

// MARK: - Main Domain Row

/// The main domain row with horizontal scroll for additional domains
private struct MainDomainRow: View {
    let mainDomain: String
    let additionalDomains: [String]
    @Binding var showAllDomains: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "globe")
                .font(.system(size: 11))
                .foregroundColor(.vercelSecondaryText)
                .frame(width: 11, height: 11)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // Main domain
                    DomainPill(domain: mainDomain)
                    
                    // Additional domains when expanded
                    if showAllDomains {
                        ForEach(additionalDomains, id: \.self) { domain in
                            DomainRow(domain: domain)
                        }
                        
                        // Show Less button
                        PillButton(title: "Show Less") {
                            withAnimation {
                                showAllDomains = false
                            }
                        }
                    } else if !additionalDomains.isEmpty {
                        // +X more button
                        PillButton(title: "+\(additionalDomains.count) more") {
                            withAnimation {
                                showAllDomains = true
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Domain Row Item

/// A domain row with an icon (for branch/commit domains)
struct DomainRowItem<Icon: View>: View {
    let icon: Icon
    let domain: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            icon
                .frame(width: 11, height: 11)
            
            Button(action: {
                if let url = URL(string: "https://\(domain)") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Text(domain)
                    .font(.vercelBody)
                    .foregroundColor(.vercelPrimaryText)
                    .lineLimit(1)
                    .underlineOnHover()
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Domain Row

/// A simple domain button with hover effect
struct DomainRow: View {
    let domain: String
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://\(domain)") {
                NSWorkspace.shared.open(url)
            }
        }) {
            Text(domain)
                .font(.vercelBody)
                .foregroundColor(.vercelPrimaryText)
                .underlineOnHover()
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(isHovered ? Color.vercelHover : Color.vercelBackground)
                .cornerRadius(3)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Domain Pill

/// A domain displayed as a minimal pill button
private struct DomainPill: View {
    let domain: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://\(domain)") {
                NSWorkspace.shared.open(url)
            }
        }) {
            Text(domain)
                .font(.vercelBody)
                .foregroundColor(.vercelPrimaryText)
                .underlineOnHover()
                .padding(.horizontal, 0)
                .padding(.vertical, 1)
                .background(Color.vercelBackground)
                .cornerRadius(3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pill Button

/// A small pill-shaped button for actions like "Show Less" or "+X more"
private struct PillButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.vercelCaption)
                .foregroundColor(.vercelSecondaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.vercelBackground)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.vercelBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .pointerOnHover()
    }
}

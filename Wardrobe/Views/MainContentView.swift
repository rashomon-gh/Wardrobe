//
//  MainContentView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData

struct MainContentView: View {
    @State private var selectedSection: NavigationSection = .screenshots
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            detailView
                .navigationSplitViewColumnWidth(min: 700, ideal: 900)
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(.dark)
        .frame(minWidth: 1000, minHeight: 650)
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .screenshots:
            GalleryView()
        case .collections:
            PlaceholderView(title: "Collections", icon: "folder", message: "Organize your screenshots into custom collections")
        case .quickLinks:
            PlaceholderView(title: "Quick Links", icon: "link", message: "Save and organize your important links")
        case .reOrganizer:
            PlaceholderView(title: "Re-Organizer", icon: "arrow.triangle.2.circlepath", message: "Auto-organize your screenshots with AI")
        case .spaceSaver:
            PlaceholderView(title: "Space Saver", icon: "internaldrive", message: "Free up disk space by managing screenshots")
        case .duplicateFinder:
            PlaceholderView(title: "Duplicate Finder", icon: "doc.on.doc", message: "Find and remove duplicate screenshots")
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    MainContentView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
}

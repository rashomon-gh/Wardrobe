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
            CollectionsView()
        case .quickLinks:
            QuickLinksView()
        case .reOrganizer:
            ReOrganizerView()
        case .spaceSaver:
            SpaceSaverView()
        case .duplicateFinder:
            DuplicateFinderView()
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

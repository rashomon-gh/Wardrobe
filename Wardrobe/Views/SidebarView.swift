//
//  SidebarView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedSection: NavigationSection
    
    @Query private var allImages: [ImageRecord]
    
    private let libraryItems: [NavigationSection] = [.screenshots, .collections, .quickLinks]
    private let toolItems: [NavigationSection] = [.reOrganizer, .spaceSaver, .duplicateFinder]
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionGroup(title: "LIBRARY", items: libraryItems)
                    sectionGroup(title: "TOOLS", items: toolItems)
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            Divider()
            
            settingsButton
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
    
    private var headerView: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Wardrobe")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
        }
        .padding(16)
    }
    
    private func sectionGroup(title: String, items: [NavigationSection]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
            
            ForEach(items) { item in
                sidebarItem(item)
            }
        }
    }
    
    private func sidebarItem(_ section: NavigationSection) -> some View {
        Button {
            selectedSection = section
        } label: {
            HStack(spacing: 12) {
                Image(systemName: section.iconName)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                Text(section.rawValue)
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
                
                if section == .screenshots && !allImages.isEmpty {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(selectedSection == section ? Color.primary : Color.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedSection == section ? Color.white.opacity(0.08) : Color.clear)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
    
    private var settingsButton: some View {
        Button {
            // Settings action
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                Text("Settings")
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SidebarView(selectedSection: .constant(.screenshots))
        .modelContainer(for: ImageRecord.self, inMemory: true)
        .frame(width: 240, height: 600)
        .preferredColorScheme(.dark)
}

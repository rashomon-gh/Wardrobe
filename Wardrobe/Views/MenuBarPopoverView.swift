//
//  MenuBarPopoverView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct MenuBarPopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    
    @Query(sort: \ImageRecord.dateAdded, order: .reverse) private var allImages: [ImageRecord]
    
    @State private var searchQuery = ""
    @State private var searchResults: [SearchService.SearchResult] = []
    @State private var isSearching = false
    @State private var isProcessing = false
    @State private var isDragTargeted = false
    
    private var displayImages: [ImageRecord] {
        if searchQuery.isEmpty {
            return Array(allImages.prefix(30))
        }
        return searchResults.map { $0.record }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            searchSection
            
            Divider()
            
            contentArea
            
            Divider()
            
            footerView
        }
        .frame(width: 380, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
        .onDrop(of: [.image], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .overlay {
            if isDragTargeted {
                dragOverlay
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text(searchQuery.isEmpty ? "Recent Screenshots" : "Search Results")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            Button {
                // Toggle view mode (future feature)
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    private var searchSection: some View {
        SearchBarView(searchQuery: $searchQuery, onSearch: performSearch, placeholder: "Search screenshots...")
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private var contentArea: some View {
        if isProcessing {
            processingView
        } else if isSearching {
            VStack {
                ProgressView()
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if displayImages.isEmpty {
            emptyStateView
        } else {
            thumbnailGrid
        }
    }
    
    private var thumbnailGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(displayImages, id: \.id) { record in
                    MenuBarThumbnail(record: record)
                        .onTapGesture {
                            NSWorkspace.shared.open(record.fileURL)
                        }
                }
            }
            .padding(12)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Processing...")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            
            Text(searchQuery.isEmpty ? "No screenshots yet" : "No results")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            
            if searchQuery.isEmpty {
                Text("Drop images here to add")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var dragOverlay: some View {
        ZStack {
            Color.accentColor.opacity(0.15)
            
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
                Text("Drop to add")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .allowsHitTesting(false)
    }
    
    private var footerView: some View {
        HStack {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                openWindow(id: "main-window")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Text("Open Dashboard")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    private func performSearch() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await SearchService.shared.search(
                    query: trimmedQuery,
                    in: modelContext,
                    limit: 30
                )
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard !providers.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    do {
                        let fileURL = try await StorageManager.shared.saveImage(from: provider)
                        let (extractedText, embedding, detectedURLs, smartTags, featurePrint, entities) = try await ProcessingService.shared.processImage(at: fileURL)
                        
                        await MainActor.run {
                            let record = ImageRecord(
                                filename: fileURL.lastPathComponent,
                                fileURL: fileURL,
                                extractedText: extractedText.isEmpty ? nil : extractedText,
                                textEmbedding: embedding,
                                detectedURLs: detectedURLs,
                                smartTags: smartTags,
                                featurePrintData: featurePrint,
                                extractedEntities: entities
                            )
                            modelContext.insert(record)
                            try? modelContext.save()
                        }
                    } catch {
                        print("Failed to process dropped image: \(error)")
                    }
                }
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
}

struct MenuBarThumbnail: View {
    let record: ImageRecord
    
    @State private var image: NSImage?
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.15))
            
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundStyle(.tertiary)
            }
            
            Text(timeString)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.7))
                )
                .padding(4)
        }
        .aspectRatio(4/3, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: record.dateAdded)
    }
    
    private func loadImage() {
        guard image == nil else { return }
        let url = record.fileURL
        
        Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url),
                  let nsImage = NSImage(data: data) else { return }
            await MainActor.run {
                self.image = nsImage
            }
        }
    }
}

#Preview {
    MenuBarPopoverView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
}

//
//  GalleryView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum GalleryViewMode {
    case grid
    case list
}

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageRecord.dateAdded, order: .reverse) private var allImages: [ImageRecord]
    @Query(sort: \ImageCollection.dateCreated, order: .reverse) private var allCollections: [ImageCollection]
    
    @State private var searchQuery = ""
    @State private var searchResults: [SearchService.SearchResult] = []
    @State private var isSearching = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var selectedImage: ImageRecord?
    @State private var zoomLevel: Double = 200
    @State private var viewMode: GalleryViewMode = .grid
    @State private var isDragTargeted = false
    @State private var showingDirectoryImporter = false
    
    private var displayImages: [ImageRecord] {
        if searchQuery.isEmpty {
            return allImages
        }
        return searchResults.map { $0.record }
    }
    
    private var groupedImages: [(key: String, value: [ImageRecord])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let groups = Dictionary(grouping: displayImages) { image -> String in
            let imageDay = calendar.startOfDay(for: image.dateAdded)
            
            if imageDay == today {
                return "Today"
            } else if imageDay == yesterday {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                return formatter.string(from: imageDay)
            }
        }
        
        let sortOrder: (String) -> Int = { key in
            if key == "Today" { return 0 }
            if key == "Yesterday" { return 1 }
            return 2
        }
        
        return groups.sorted { a, b in
            let aSort = sortOrder(a.key)
            let bSort = sortOrder(b.key)
            if aSort != bSort { return aSort < bSort }
            // For dates, sort by most recent first
            return (a.value.first?.dateAdded ?? Date()) > (b.value.first?.dateAdded ?? Date())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            
            Divider()
            
            if allImages.isEmpty {
                emptyStateView
            } else {
                galleryContent
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.image], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .overlay {
            if isDragTargeted {
                dragOverlay
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(item: $selectedImage) { image in
            ImageDetailView(image: image, onDelete: deleteImage)
        }
        .fileImporter(
            isPresented: $showingDirectoryImporter,
            allowedContentTypes: [.directory],
            allowsMultipleSelection: false
        ) { result in
            handleDirectoryImport(result: result)
        }
    }
    
    private var toolbarView: some View {
        HStack(spacing: 16) {
            Text("Gallery")
                .font(.system(size: 28, weight: .bold))
            
            SemanticSearchBar(searchQuery: $searchQuery, onSearch: performSearch, onClear: clearSearch)
                .frame(maxWidth: 380)
            
            Spacer()
            
            zoomControls
            
            viewToggleButtons
            
            actionButtons
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var zoomControls: some View {
        HStack(spacing: 8) {
            Image(systemName: "minus.magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            Slider(value: $zoomLevel, in: 120...320)
                .frame(width: 100)
                .controlSize(.small)
            
            Image(systemName: "plus.magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
    
    private var viewToggleButtons: some View {
        HStack(spacing: 2) {
            Button {
                viewMode = .list
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 13))
                    .frame(width: 28, height: 24)
                    .foregroundStyle(viewMode == .list ? Color.white : Color.secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(viewMode == .list ? Color.accentColor : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            
            Button {
                viewMode = .grid
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13))
                    .frame(width: 28, height: 24)
                    .foregroundStyle(viewMode == .grid ? Color.white : Color.secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(viewMode == .grid ? Color.accentColor : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.secondary.opacity(0.15))
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                showingDirectoryImporter = true
            } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Import folder")
            
            Button {
                // Quick actions
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Select images")
            
            Button {
                openImagesFolder()
            } label: {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Open folder")
        }
    }
    
    @ViewBuilder
    private var galleryContent: some View {
        if isSearching {
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Searching...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if displayImages.isEmpty && !searchQuery.isEmpty {
            noResultsView
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 32, pinnedViews: []) {
                    ForEach(groupedImages, id: \.key) { group in
                        dateGroupSection(title: group.key, images: group.value)
                    }
                }
                .padding(24)
            }
        }
    }
    
    private func dateGroupSection(title: String, images: [ImageRecord]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: zoomLevel, maximum: zoomLevel * 1.3), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(images, id: \.id) { image in
                    ImageCardView(
                        record: image,
                        similarity: searchResults.first(where: { $0.record.id == image.id })?.similarity,
                        thumbnailMaxPixelSize: zoomLevel * 2
                    )
                    .onTapGesture {
                        selectedImage = image
                    }
                    .contextMenu {
                        Button {
                            QuickLookPreviewer.shared.preview(urls: [image.fileURL])
                        } label: {
                            Label("Quick Look", systemImage: "eye")
                        }
                        .keyboardShortcut(.space, modifiers: [])
                        
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([image.fileURL])
                        } label: {
                            Label("Show in Finder", systemImage: "folder")
                        }
                        
                        if !allCollections.isEmpty {
                            Menu {
                                ForEach(allCollections) { collection in
                                    let isMember = collection.images.contains { $0.id == image.id }
                                    Button {
                                        toggleMembership(image: image, collection: collection)
                                    } label: {
                                        Label(
                                            collection.name,
                                            systemImage: isMember ? "checkmark.circle.fill" : collection.iconName
                                        )
                                    }
                                }
                            } label: {
                                Label("Add to Collection", systemImage: "folder.badge.plus")
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            deleteImage(image)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            DropZoneView(
                isProcessing: isProcessing,
                onDrop: { providers in
                    handleDrop(providers: providers)
                }
            )
            .frame(maxWidth: 600, maxHeight: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No results")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Try a different search query")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var dragOverlay: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            
            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
                Text("Drop images to add")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .allowsHitTesting(false)
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
                    limit: 100
                )
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isSearching = false
                }
            }
        }
    }
    
    private func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
    
    private func handleDirectoryImport(result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard let directoryURL = urls.first else { return }
            importDirectory(directoryURL)
        case .failure(let error):
            errorMessage = "Failed to open directory: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func importDirectory(_ directoryURL: URL) {
        isProcessing = true
        
        Task {
            do {
                let importedImages = try await StorageManager.shared.importImages(fromDirectory: directoryURL)
                guard !importedImages.isEmpty else {
                    await MainActor.run {
                        errorMessage = "No image files were found in the selected folder."
                        showingError = true
                        isProcessing = false
                    }
                    return
                }
                
                for imported in importedImages {
                    let processed = try await ProcessingService.shared.processImage(at: imported.copiedURL)
                    
                    await MainActor.run {
                        let record = ImageRecord(
                            filename: imported.copiedURL.lastPathComponent,
                            fileURL: imported.copiedURL,
                            extractedText: processed.text.isEmpty ? nil : processed.text,
                            textEmbedding: processed.embedding,
                            sourceRelativePath: imported.sourceRelativePath,
                            sourceTopLevelFolder: imported.sourceTopLevelFolder,
                            detectedURLs: processed.urls,
                            smartTags: processed.smartTags,
                            featurePrintData: processed.featurePrint,
                            extractedEntities: processed.entities
                        )
                        modelContext.insert(record)
                    }
                }
                
                await MainActor.run {
                    try? modelContext.save()
                    isProcessing = false
                    if !searchQuery.isEmpty {
                        performSearch()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to import folder: \(error.localizedDescription)"
                    showingError = true
                    isProcessing = false
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
                                sourceRelativePath: nil,
                                sourceTopLevelFolder: nil,
                                detectedURLs: detectedURLs,
                                smartTags: smartTags,
                                featurePrintData: featurePrint,
                                extractedEntities: entities
                            )
                            modelContext.insert(record)
                            try? modelContext.save()
                        }
                    } catch {
                        await MainActor.run {
                            self.errorMessage = "Failed to process image: \(error.localizedDescription)"
                            self.showingError = true
                        }
                    }
                }
            }
            
            await MainActor.run {
                isProcessing = false
                if !searchQuery.isEmpty {
                    performSearch()
                }
            }
        }
    }
    
    private func toggleMembership(image: ImageRecord, collection: ImageCollection) {
        if collection.images.contains(where: { $0.id == image.id }) {
            collection.images.removeAll { $0.id == image.id }
        } else {
            collection.images.append(image)
        }
        try? modelContext.save()
    }
    
    private func deleteImage(_ image: ImageRecord) {
        let url = image.fileURL
        modelContext.delete(image)
        try? modelContext.save()
        
        Task.detached {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    private func openImagesFolder() {
        guard let appDirectory = AppSettings.imageLibraryURL() else {
            errorMessage = "Storage directory is not available."
            showingError = true
            return
        }
        
        do {
            try FileManager.default.createDirectory(
                at: appDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            NSWorkspace.shared.open(appDirectory)
        } catch {
            errorMessage = "Failed to open folder: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    GalleryView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
}

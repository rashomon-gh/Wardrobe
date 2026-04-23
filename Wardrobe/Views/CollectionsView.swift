//
//  CollectionsView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData
import AppKit

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageRecord.dateAdded, order: .reverse) private var allImages: [ImageRecord]
    @Query(sort: \ImageCollection.dateCreated, order: .reverse) private var userCollections: [ImageCollection]
    
    @State private var selectedSmart: SmartCollection?
    @State private var selectedUser: ImageCollection?
    @State private var previewImage: ImageRecord?
    @State private var showingNewCollectionSheet = false
    
    private func imagesIn(_ collection: SmartCollection) -> [ImageRecord] {
        allImages.filter { collection.matches(date: $0.dateAdded) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let smart = selectedSmart {
                smartCollectionDetailView(for: smart)
            } else if let user = selectedUser {
                userCollectionDetailView(for: user)
            } else {
                collectionsOverview
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $previewImage) { image in
            ImageDetailView(image: image, onDelete: deleteImage)
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            NewCollectionSheet()
                .environment(\.modelContext, modelContext)
        }
    }
    
    private var collectionsOverview: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Collections")
                        .font(.system(size: 28, weight: .bold))
                    Text("Auto-organized by date, plus your own folders.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingNewCollectionSheet = true
                } label: {
                    Label("New Collection", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.accentColor)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    smartCollectionsSection
                    userCollectionsSection
                }
                .padding(24)
            }
        }
    }
    
    private var smartCollectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SMART COLLECTIONS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 16)],
                spacing: 16
            ) {
                ForEach(SmartCollection.allCases) { collection in
                    smartCollectionTile(collection)
                }
            }
        }
    }
    
    private var userCollectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY COLLECTIONS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .tracking(0.5)
                Spacer()
            }
            
            if userCollections.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                    Text("No custom collections yet. Create one to group your screenshots.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Create") {
                        showingNewCollectionSheet = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                .foregroundStyle(.tertiary)
                        )
                )
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(userCollections) { collection in
                        userCollectionTile(collection)
                    }
                }
            }
        }
    }
    
    private func smartCollectionTile(_ collection: SmartCollection) -> some View {
        let images = imagesIn(collection)
        let count = images.count
        
        return Button {
            selectedSmart = collection
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: collection.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: collection.iconName)
                            .font(.system(size: 44, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85))
                    )
                }
                .frame(height: 120)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(collection.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("\(count) screenshot\(count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
    
    private func userCollectionTile(_ collection: ImageCollection) -> some View {
        let count = collection.images.count
        
        return Button {
            selectedUser = collection
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    collection.color
                        .overlay(
                            Image(systemName: collection.iconName)
                                .font(.system(size: 44, weight: .regular))
                                .foregroundStyle(.white.opacity(0.9))
                        )
                }
                .frame(height: 120)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(collection.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("\(count) screenshot\(count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(collection)
                try? modelContext.save()
            } label: {
                Label("Delete Collection", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func smartCollectionDetailView(for collection: SmartCollection) -> some View {
        let images = imagesIn(collection)
        
        collectionDetailShell(
            title: collection.title,
            subtitle: "\(images.count) screenshot\(images.count == 1 ? "" : "s")",
            icon: collection.iconName,
            gradient: collection.gradient,
            onBack: { selectedSmart = nil },
            images: images,
            emptyMessage: "Screenshots from \(collection.title.lowercased()) will appear here automatically.",
            imageContextMenu: { _ in EmptyView() }
        )
    }
    
    @ViewBuilder
    private func userCollectionDetailView(for collection: ImageCollection) -> some View {
        let images = collection.images.sorted { $0.dateAdded > $1.dateAdded }
        
        collectionDetailShell(
            title: collection.name,
            subtitle: "\(images.count) screenshot\(images.count == 1 ? "" : "s")",
            icon: collection.iconName,
            gradient: [collection.color, collection.color.opacity(0.7)],
            onBack: { selectedUser = nil },
            images: images,
            emptyMessage: "Right-click any screenshot in the gallery and add it to this collection.",
            imageContextMenu: { image in
                Button(role: .destructive) {
                    removeFromCollection(image: image, collection: collection)
                } label: {
                    Label("Remove from \(collection.name)", systemImage: "minus.circle")
                }
            }
        )
    }
    
    @ViewBuilder
    private func collectionDetailShell<Menu: View>(
        title: String,
        subtitle: String,
        icon: String,
        gradient: [Color],
        onBack: @escaping () -> Void,
        images: [ImageRecord],
        emptyMessage: String,
        @ViewBuilder imageContextMenu: @escaping (ImageRecord) -> Menu
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Collections")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                    }
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            if images.isEmpty {
                emptyCollectionView(icon: icon, title: title, message: emptyMessage)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(images, id: \.id) { image in
                            ImageCardView(record: image, similarity: nil)
                                .onTapGesture {
                                    previewImage = image
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
                                    
                                    imageContextMenu(image)
                                }
                        }
                    }
                    .padding(24)
                }
            }
        }
    }
    
    private func emptyCollectionView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("Nothing here yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func removeFromCollection(image: ImageRecord, collection: ImageCollection) {
        collection.images.removeAll { $0.id == image.id }
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
}

struct NewCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColorHex = CollectionPalette.presets.first?.hex ?? "#7B61FF"
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("New Collection")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("e.g. Design inspiration", text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.secondary.opacity(0.12))
                    )
                    .focused($nameFocused)
                    .onSubmit(submit)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ForEach(CollectionPalette.presets, id: \.hex) { preset in
                        Button {
                            selectedColorHex = preset.hex
                        } label: {
                            Circle()
                                .fill(Color(hex: preset.hex) ?? .accentColor)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(selectedColorHex == preset.hex ? 0.8 : 0), lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(preset.name)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 10),
                    spacing: 8
                ) {
                    ForEach(CollectionPalette.icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                .frame(width: 30, height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? .accentColor) : Color.secondary.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") { submit() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 440)
        .onAppear { nameFocused = true }
    }
    
    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let collection = ImageCollection(
            name: trimmed,
            iconName: selectedIcon,
            colorHex: selectedColorHex
        )
        modelContext.insert(collection)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CollectionsView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
        .frame(width: 900, height: 700)
}

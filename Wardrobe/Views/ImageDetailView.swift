//
//  ImageDetailView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import AppKit
import SwiftData

struct ImageDetailView: View {
    let image: ImageRecord
    let onDelete: (ImageRecord) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageCollection.dateCreated, order: .reverse) private var allCollections: [ImageCollection]
    @State private var nsImage: NSImage?
    @State private var justCopied = false
    @State private var newTag = ""
    @State private var notesDraft = ""
    @State private var notesFocused = false
    @FocusState private var isNewTagFocused: Bool
    @FocusState private var isNotesFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            HStack(spacing: 0) {
                imagePreview
                    .frame(maxWidth: .infinity)
                
                Divider()
                
                metadataPanel
                    .frame(width: 300)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            loadImage()
            notesDraft = image.notes ?? ""
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(image.filename)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(formattedDate)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    QuickLookPreviewer.shared.preview(urls: [image.fileURL])
                } label: {
                    Image(systemName: "eye")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Quick Look")
                .keyboardShortcut(.space, modifiers: [])
                
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([image.fileURL])
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Show in Finder")
                
                Button {
                    NSWorkspace.shared.open(image.fileURL)
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Open in default app")
                
                Button {
                    onDelete(image)
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Delete")
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
        }
        .padding(16)
    }
    
    private var imagePreview: some View {
        ZStack {
            Color.black.opacity(0.3)
            
            if let nsImage = nsImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
            } else {
                ProgressView()
            }
        }
    }
    
    private var metadataPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                metadataSection
                
                collectionsSection
                
                customTagsSection
                
                if !image.smartTags.isEmpty {
                    smartTagsSection
                }
                
                notesSection
                
                if !image.detectedURLs.isEmpty {
                    detectedLinksSection
                }
                
                if let text = image.extractedText, !text.isEmpty {
                    extractedTextSection(text)
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Details")
            
            metadataRow(label: "Filename", value: image.filename)
            metadataRow(label: "Created", value: formattedDate)
            
            if let size = fileSize {
                metadataRow(label: "Size", value: size)
            }
            
            if let dimensions = imageDimensions {
                metadataRow(label: "Dimensions", value: dimensions)
            }
            
            if let embedding = image.textEmbedding {
                metadataRow(label: "Embedding", value: "\(embedding.count) dimensions")
            }
        }
    }
    
    private func extractedTextSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeader("Extracted Text")
                Spacer()
                copyTextButton(text: text)
            }
            
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }
    
    private func copyTextButton(text: String) -> some View {
        Button {
            copyExtractedText(text)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10, weight: .semibold))
                Text(justCopied ? "Copied" : "Copy Text")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(justCopied ? Color.green : Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill((justCopied ? Color.green : Color.accentColor).opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .help("Copy extracted text to clipboard")
    }
    
    private func copyExtractedText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.15)) {
            justCopied = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.15)) {
                    justCopied = false
                }
            }
        }
    }
    
    private var collectionsSection: some View {
        let memberships = allCollections.filter { c in c.images.contains { $0.id == image.id } }
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.blue)
                sectionHeader("Collections")
                Spacer()
                if !allCollections.isEmpty {
                    Menu {
                        ForEach(allCollections) { collection in
                            let isMember = memberships.contains { $0.id == collection.id }
                            Button {
                                toggleMembership(for: collection)
                            } label: {
                                Label(
                                    collection.name,
                                    systemImage: isMember ? "checkmark.circle.fill" : collection.iconName
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.blue)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                }
            }
            
            if memberships.isEmpty {
                Text(allCollections.isEmpty ? "No collections yet. Create one from the Collections tab." : "Not in any collection yet.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(memberships) { collection in
                        HStack(spacing: 5) {
                            Image(systemName: collection.iconName)
                                .font(.system(size: 9, weight: .semibold))
                            Text(collection.name)
                                .font(.system(size: 10, weight: .semibold))
                            Button {
                                removeFromCollection(collection)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .opacity(0.7)
                            }
                            .buttonStyle(.plain)
                        }
                        .foregroundStyle(collection.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(collection.color.opacity(0.15))
                        )
                    }
                }
            }
        }
    }
    
    private func toggleMembership(for collection: ImageCollection) {
        if collection.images.contains(where: { $0.id == image.id }) {
            collection.images.removeAll { $0.id == image.id }
        } else {
            collection.images.append(image)
        }
        try? modelContext.save()
    }
    
    private func removeFromCollection(_ collection: ImageCollection) {
        collection.images.removeAll { $0.id == image.id }
        try? modelContext.save()
    }
    
    private var smartTagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.purple)
                sectionHeader("Smart Tags")
            }
            
            FlowLayout(spacing: 6) {
                ForEach(image.smartTags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text("#\(tag)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.15))
                    )
                }
            }
        }
    }
    
    private var detectedLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.cyan)
                sectionHeader("Smart Links")
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(image.detectedURLs, id: \.self) { link in
                    Button {
                        if let url = URL(string: link) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                            Text(QuickLinksView.domain(for: link) ?? link)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .foregroundStyle(Color.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .help(link)
                }
            }
        }
    }
    
    private var customTagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.orange)
                sectionHeader("Custom Tags")
            }
            
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.orange)
                
                TextField("Add tag...", text: $newTag)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isNewTagFocused)
                    .onSubmit(commitNewTag)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.orange.opacity(isNewTagFocused ? 0.5 : 0.2), lineWidth: 1)
                    )
            )
            
            if !image.customTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(image.customTags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
    }
    
    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.orange)
            
            Button {
                removeTag(tag)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.orange.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.orange)
                sectionHeader("Notes")
            }
            
            TextEditor(text: $notesDraft)
                .focused($isNotesFocused)
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 60, maxHeight: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.orange.opacity(isNotesFocused ? 0.4 : 0.15), lineWidth: 1)
                        )
                )
                .overlay(alignment: .topLeading) {
                    if notesDraft.isEmpty {
                        Text("Add a note...")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: notesDraft) { _, newValue in
                    saveNotes(newValue)
                }
        }
    }
    
    private func commitNewTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !image.customTags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            image.customTags.append(trimmed)
            try? modelContext.save()
        }
        
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        image.customTags.removeAll { $0 == tag }
        try? modelContext.save()
    }
    
    private func saveNotes(_ newValue: String) {
        let normalized = newValue.isEmpty ? nil : newValue
        guard image.notes != normalized else { return }
        image.notes = normalized
        try? modelContext.save()
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.tertiary)
            .tracking(0.5)
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: image.dateAdded)
    }
    
    private var fileSize: String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: image.fileURL.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private var imageDimensions: String? {
        guard let nsImage = nsImage else { return nil }
        let size = nsImage.size
        return "\(Int(size.width)) × \(Int(size.height))"
    }
    
    private func loadImage() {
        let url = image.fileURL
        Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url),
                  let loaded = NSImage(data: data) else { return }
            await MainActor.run {
                self.nsImage = loaded
            }
        }
    }
}

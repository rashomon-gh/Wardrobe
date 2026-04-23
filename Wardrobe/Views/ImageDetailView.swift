//
//  ImageDetailView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import AppKit

struct ImageDetailView: View {
    let image: ImageRecord
    let onDelete: (ImageRecord) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var nsImage: NSImage?
    
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
        .onAppear(perform: loadImage)
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
            sectionHeader("Extracted Text")
            
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

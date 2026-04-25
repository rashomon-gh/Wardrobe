//
//  SpaceSaverView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData
import AppKit

struct SpaceSaverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageRecord.dateAdded, order: .reverse) private var allImages: [ImageRecord]
    
    @State private var selectedLevel: CompressionLevel = .balanced
    @State private var isCompressing = false
    @State private var progress: Double = 0
    @State private var processed = 0
    @State private var totalBytesSaved: Int64 = 0
    @State private var lastRunSavings: Int64 = 0
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingConfirmation = false
    
    private var compressibleImages: [ImageRecord] {
        allImages.filter { record in
            let ext = record.fileURL.pathExtension.lowercased()
            return ext == "png" || ext == "tiff" || ext == "tif" || ext == "bmp"
        }
    }
    
    private var originalTotalBytes: Int64 {
        allImages.reduce(0) { $0 + SpaceSaverService.fileSize(at: $1.fileURL) }
    }
    
    private var projectedSavings: Int64 {
        let compressible = compressibleImages.reduce(Int64(0)) {
            $0 + SpaceSaverService.fileSize(at: $1.fileURL)
        }
        let ratio: Double
        switch selectedLevel {
        case .high: ratio = 0.3
        case .balanced: ratio = 0.5
        case .max: ratio = 0.7
        }
        return Int64(Double(compressible) * ratio)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            
            if allImages.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            "Compress \(compressibleImages.count) images?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Compress with \(selectedLevel.title)", role: .destructive) {
                runCompression()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will re-encode PNG, TIFF, and BMP screenshots as JPEG (.jpg) to save disk space. The originals cannot be restored afterwards.")
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Space Saver")
                    .font(.system(size: 28, weight: .bold))
                Text("Converts PNG, TIFF, and BMP screenshots to compressed JPEG (.jpg) with 3 quality levels.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                statsPanel
                
                levelPicker
                
                actionPanel
            }
            .padding(24)
        }
    }
    
    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(projectedReductionPercent)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Reduction")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                sizeBar(label: "Original Size", bytes: originalTotalBytes, total: originalTotalBytes, color: .orange)
                sizeBar(label: "Projected After", bytes: max(0, originalTotalBytes - projectedSavings), total: originalTotalBytes, color: .teal)
            }
            
            HStack(spacing: 12) {
                Label("\(formatBytes(projectedSavings)) potential savings", systemImage: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.teal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.teal.opacity(0.15))
                    )
                
                if totalBytesSaved > 0 {
                    Label("\(formatBytes(totalBytesSaved)) saved so far", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }
    
    private func sizeBar(label: String, bytes: Int64, total: Int64, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatBytes(bytes))
                    .font(.system(size: 11, weight: .semibold))
            }
            GeometryReader { geo in
                let width = total > 0 ? CGFloat(Double(bytes) / Double(total)) * geo.size.width : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.8))
                        .frame(width: max(4, width))
                }
            }
            .frame(height: 8)
        }
    }
    
    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUALITY LEVEL")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            
            HStack(spacing: 10) {
                ForEach(CompressionLevel.allCases) { level in
                    levelTile(level)
                }
            }
        }
    }
    
    private func levelTile(_ level: CompressionLevel) -> some View {
        Button {
            selectedLevel = level
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(level.title)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    if selectedLevel == level {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(level.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedLevel == level ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedLevel == level ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(compressibleImages.count) compressible images in library")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text("Space Saver re-encodes PNG, TIFF, and BMP files as JPEG (.jpg). It keeps the original file only when JPEG would not save space.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            
            if isCompressing {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Compressing \(processed)/\(compressibleImages.count)")
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                        Text("\(formatBytes(lastRunSavings)) saved")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    ProgressView(value: progress)
                }
            } else {
                Button {
                    showingConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Compress library")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(compressibleImages.isEmpty)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.06))
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "internaldrive")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No images to compress")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Add some screenshots and Space Saver can free up disk for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var projectedReductionPercent: String {
        guard originalTotalBytes > 0 else { return "0%" }
        let percent = Double(projectedSavings) / Double(originalTotalBytes) * 100
        return "\(Int(percent))%"
    }
    
    private func runCompression() {
        guard !isCompressing else { return }
        let targets = compressibleImages
        guard !targets.isEmpty else { return }
        
        isCompressing = true
        processed = 0
        progress = 0
        lastRunSavings = 0
        
        let level = selectedLevel
        
        Task {
            for record in targets {
                let originalURL = record.fileURL
                do {
                    let result = try await SpaceSaverService.shared.compress(url: originalURL, level: level)
                    await MainActor.run {
                        if result.newURL != originalURL {
                            record.fileURL = result.newURL
                            record.filename = result.newURL.lastPathComponent
                        }
                        lastRunSavings += max(0, result.saved)
                        totalBytesSaved += max(0, result.saved)
                        processed += 1
                        progress = Double(processed) / Double(targets.count)
                    }
                } catch {
                    await MainActor.run {
                        processed += 1
                        progress = Double(processed) / Double(targets.count)
                    }
                }
            }
            
            await MainActor.run {
                try? modelContext.save()
                isCompressing = false
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    SpaceSaverView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
        .frame(width: 900, height: 700)
}

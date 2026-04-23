//
//  DuplicateFinderView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData
import AppKit

struct DuplicateFinderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageRecord.dateAdded, order: .reverse) private var allImages: [ImageRecord]
    
    @State private var groups: [DuplicateFinderService.DuplicateGroup] = []
    @State private var isScanning = false
    @State private var isBackfilling = false
    @State private var backfilled = 0
    @State private var removedCount = 0
    @State private var bytesRecovered: Int64 = 0
    
    private var imagesWithoutFeaturePrint: [ImageRecord] {
        allImages.filter { $0.featurePrintData == nil }
    }
    
    private var totalGroupItems: Int {
        groups.reduce(0) { $0 + $1.records.count }
    }
    
    private var estimatedSpaceIfDeduped: Int64 {
        // Sum of sizes of all duplicates beyond the keeper in each group
        groups.reduce(0) { partial, group in
            let toRemove = Array(group.records.dropFirst())
            return partial + toRemove.reduce(0) { $0 + fileSize(for: $1.fileURL) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            contentView
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if groups.isEmpty && imagesWithoutFeaturePrint.isEmpty {
                runScan()
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Duplicate Finder")
                    .font(.system(size: 28, weight: .bold))
                Text("Visual similarity analysis finds near-identical screenshots.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !imagesWithoutFeaturePrint.isEmpty {
                Button {
                    backfillFeaturePrints()
                } label: {
                    HStack(spacing: 6) {
                        if isBackfilling {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(isBackfilling
                             ? "Indexing \(backfilled)/\(imagesWithoutFeaturePrint.count)..."
                             : "Index \(imagesWithoutFeaturePrint.count) images")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.15))
                    )
                    .foregroundStyle(Color.orange)
                }
                .buttonStyle(.plain)
                .disabled(isBackfilling)
            }
            
            Button {
                runScan()
            } label: {
                HStack(spacing: 6) {
                    if isScanning {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(isScanning ? "Scanning..." : "Scan for duplicates")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.15))
                )
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(isScanning)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private var contentView: some View {
        if isScanning && groups.isEmpty {
            ProgressView("Analyzing images...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if groups.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statsBanner
                    
                    ForEach(groups) { group in
                        duplicateGroupCard(group)
                    }
                }
                .padding(24)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green.opacity(0.7))
            
            Text(removedCount > 0 ? "All cleaned up!" : "No duplicates found")
                .font(.title3)
                .fontWeight(.semibold)
            
            if removedCount > 0 {
                Text("Removed \(removedCount) duplicates — recovered \(formatBytes(bytesRecovered)).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(imagesWithoutFeaturePrint.isEmpty
                     ? "Your library looks clean."
                     : "Index your existing screenshots first to enable duplicate detection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var statsBanner: some View {
        HStack(spacing: 24) {
            statItem(label: "Duplicates Found", value: "\(totalGroupItems)", color: .pink)
            Divider().frame(height: 40)
            statItem(label: "Space Recoverable", value: formatBytes(estimatedSpaceIfDeduped), color: .orange)
            Divider().frame(height: 40)
            statItem(label: "Groups", value: "\(groups.count)", color: .purple)
            
            Spacer()
            
            if !groups.isEmpty {
                Button {
                    cleanupAll()
                } label: {
                    Label("Remove all duplicates", systemImage: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.red.opacity(0.15))
                        )
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.08))
        )
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
    
    private func duplicateGroupCard(_ group: DuplicateFinderService.DuplicateGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(group.records.count) similar images")
                    .font(.system(size: 13, weight: .semibold))
                Text("(max distance \(String(format: "%.2f", group.maxDistance)))")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    removeDuplicates(in: group)
                } label: {
                    Label("Keep first, remove \(group.records.count - 1)", systemImage: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.15))
                        )
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)
            }
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 10)],
                spacing: 10
            ) {
                ForEach(Array(group.records.enumerated()), id: \.element.id) { index, record in
                    DuplicateThumbnailView(record: record, isKeeper: index == 0)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.06))
        )
    }
    
    private func runScan() {
        guard !isScanning else { return }
        isScanning = true
        
        let snapshot = allImages
        Task {
            let found = await DuplicateFinderService.shared.findDuplicateGroups(records: snapshot)
            await MainActor.run {
                self.groups = found
                self.isScanning = false
            }
        }
    }
    
    private func backfillFeaturePrints() {
        guard !isBackfilling else { return }
        isBackfilling = true
        backfilled = 0
        
        let targets = imagesWithoutFeaturePrint
        Task {
            for record in targets {
                let url = record.fileURL
                if let data = try? await ProcessingService.shared.generateFeaturePrint(at: url) {
                    await MainActor.run {
                        record.featurePrintData = data
                        backfilled += 1
                    }
                }
            }
            await MainActor.run {
                try? modelContext.save()
                isBackfilling = false
            }
            await MainActor.run {
                runScan()
            }
        }
    }
    
    private func removeDuplicates(in group: DuplicateFinderService.DuplicateGroup) {
        let toDelete = Array(group.records.dropFirst())
        deleteRecords(toDelete)
        groups.removeAll { $0.id == group.id }
    }
    
    private func cleanupAll() {
        var toDelete: [ImageRecord] = []
        for group in groups {
            toDelete.append(contentsOf: group.records.dropFirst())
        }
        deleteRecords(toDelete)
        groups.removeAll()
    }
    
    private func deleteRecords(_ records: [ImageRecord]) {
        var bytes: Int64 = 0
        let urls = records.map { $0.fileURL }
        for record in records {
            bytes += fileSize(for: record.fileURL)
            modelContext.delete(record)
        }
        try? modelContext.save()
        
        removedCount += records.count
        bytesRecovered += bytes
        
        Task.detached {
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    private func fileSize(for url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path))
            .flatMap { $0[.size] as? Int64 } ?? 0
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

private struct DuplicateThumbnailView: View {
    let record: ImageRecord
    let isKeeper: Bool
    
    @State private var image: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.15))
                
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                }
                
                if isKeeper {
                    Text("KEEP")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.9))
                        )
                        .padding(6)
                }
            }
            .aspectRatio(4/3, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isKeeper ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            
            Text(record.filename)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        guard image == nil else { return }
        let url = record.fileURL
        Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url),
                  let ns = NSImage(data: data) else { return }
            await MainActor.run {
                self.image = ns
            }
        }
    }
}

#Preview {
    DuplicateFinderView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
        .frame(width: 900, height: 700)
}

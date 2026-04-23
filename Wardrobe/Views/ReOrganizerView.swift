//
//  ReOrganizerView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData
import NaturalLanguage

struct ReOrganizerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageRecord.dateAdded, order: .reverse) private var allImages: [ImageRecord]
    
    @State private var isRunning = false
    @State private var processed = 0
    @State private var total = 0
    @State private var currentStep = ""
    @State private var lastRunAt: Date?
    
    private struct CoverageStat: Identifiable {
        let id: String
        let title: String
        let icon: String
        let color: Color
        let covered: Int
        let total: Int
        
        var percent: Double {
            total == 0 ? 1 : Double(covered) / Double(total)
        }
        
        var missing: Int { total - covered }
    }
    
    private var coverageStats: [CoverageStat] {
        let total = allImages.count
        return [
            CoverageStat(
                id: "ocr",
                title: "OCR Text",
                icon: "doc.text.viewfinder",
                color: .blue,
                covered: allImages.filter { ($0.extractedText?.isEmpty == false) }.count,
                total: total
            ),
            CoverageStat(
                id: "embedding",
                title: "Semantic Embedding",
                icon: "waveform.path",
                color: .purple,
                covered: allImages.filter { ($0.textEmbedding?.isEmpty == false) }.count,
                total: total
            ),
            CoverageStat(
                id: "smartTags",
                title: "Smart Tags",
                icon: "sparkles",
                color: .pink,
                covered: allImages.filter { !$0.smartTags.isEmpty }.count,
                total: total
            ),
            CoverageStat(
                id: "featurePrint",
                title: "Feature Print",
                icon: "square.stack.3d.up",
                color: .orange,
                covered: allImages.filter { $0.featurePrintData != nil }.count,
                total: total
            ),
            CoverageStat(
                id: "urls",
                title: "Link Detection",
                icon: "link",
                color: .cyan,
                covered: allImages.filter { !$0.detectedURLs.isEmpty || ($0.extractedText ?? "").isEmpty }.count,
                total: total
            )
        ]
    }
    
    private var itemsNeedingWork: [ImageRecord] {
        allImages.filter { record in
            record.extractedText == nil
                || record.textEmbedding == nil
                || record.smartTags.isEmpty
                || record.featurePrintData == nil
        }
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
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Re-Organizer")
                    .font(.system(size: 28, weight: .bold))
                Text("Auto-organize your library with on-device AI.")
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
                summaryCard
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("LIBRARY COVERAGE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .tracking(0.5)
                    
                    VStack(spacing: 8) {
                        ForEach(coverageStats) { stat in
                            coverageRow(stat)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(itemsNeedingWork.count)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("items need")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("re-organizing")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                runButton
            }
            
            if isRunning {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(currentStep)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(processed)/\(total)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    ProgressView(value: total == 0 ? 0 : Double(processed) / Double(total))
                }
            } else if let last = lastRunAt {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Last run \(formattedDate(last))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }
    
    private var runButton: some View {
        Button {
            runReOrganize()
        } label: {
            HStack(spacing: 8) {
                if isRunning {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(isRunning ? "Running..." : "Re-Organize Now")
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
        .disabled(isRunning || itemsNeedingWork.isEmpty)
        .opacity(itemsNeedingWork.isEmpty ? 0.5 : 1)
    }
    
    private func coverageRow(_ stat: CoverageStat) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(stat.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: stat.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(stat.color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(stat.title)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("\(stat.covered) / \(stat.total)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.12))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(stat.color.opacity(0.8))
                            .frame(width: max(4, CGFloat(stat.percent) * geo.size.width))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.05))
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("Nothing to re-organize yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Add some screenshots and we'll keep your library tidy automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func runReOrganize() {
        guard !isRunning else { return }
        let targets = itemsNeedingWork
        guard !targets.isEmpty else { return }
        
        isRunning = true
        processed = 0
        total = targets.count
        currentStep = "Preparing..."
        
        Task {
            let embeddingModel = NLEmbedding.sentenceEmbedding(for: .english)
            
            for record in targets {
                let url = record.fileURL
                let name = record.filename
                
                await MainActor.run {
                    currentStep = "Processing \(name)"
                }
                
                if record.extractedText == nil {
                    if let processed = try? await ProcessingService.shared.processImage(at: url) {
                        await MainActor.run {
                            record.extractedText = processed.text.isEmpty ? nil : processed.text
                            record.textEmbedding = processed.embedding
                            record.detectedURLs = processed.urls
                            record.smartTags = processed.smartTags
                            record.featurePrintData = processed.featurePrint
                        }
                    }
                } else {
                    if record.textEmbedding == nil, let text = record.extractedText, let model = embeddingModel, let vec = model.vector(for: text) {
                        var doubles = [Double]()
                        doubles.reserveCapacity(vec.count)
                        for i in 0..<vec.count { doubles.append(Double(vec[i])) }
                        await MainActor.run { record.textEmbedding = doubles }
                    }
                    if record.smartTags.isEmpty {
                        if let tags = try? await ProcessingService.shared.classifyImage(at: url) {
                            await MainActor.run { record.smartTags = tags }
                        }
                    }
                    if record.featurePrintData == nil {
                        if let fp = try? await ProcessingService.shared.generateFeaturePrint(at: url) {
                            await MainActor.run { record.featurePrintData = fp }
                        }
                    }
                    if record.detectedURLs.isEmpty, let text = record.extractedText {
                        let urls = ProcessingService.detectURLs(in: text)
                        await MainActor.run { record.detectedURLs = urls }
                    }
                }
                
                await MainActor.run {
                    processed += 1
                }
            }
            
            await MainActor.run {
                try? modelContext.save()
                isRunning = false
                currentStep = ""
                lastRunAt = Date()
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ReOrganizerView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
        .frame(width: 900, height: 700)
}

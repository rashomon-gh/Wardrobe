//
//  QuickLinksView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData
import AppKit

struct QuickLinksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageRecord.dateAdded, order: .reverse) private var allImages: [ImageRecord]
    
    @State private var searchQuery = ""
    @State private var isBackfilling = false
    @State private var backfillProgress: Double = 0
    
    struct LinkOccurrence: Identifiable {
        let id = UUID()
        let url: String
        let records: [ImageRecord]
    }
    
    private var allLinks: [LinkOccurrence] {
        var map: [String: [ImageRecord]] = [:]
        for record in allImages {
            for link in record.detectedURLs {
                map[link, default: []].append(record)
            }
        }
        return map
            .map { LinkOccurrence(url: $0.key, records: $0.value) }
            .sorted { $0.records.count > $1.records.count }
    }
    
    private var filteredLinks: [LinkOccurrence] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return allLinks }
        return allLinks.filter { $0.url.lowercased().contains(query) }
    }
    
    private var domainCounts: [(domain: String, count: Int)] {
        var counts: [String: Int] = [:]
        for link in allLinks {
            let domain = Self.domain(for: link.url) ?? link.url
            counts[domain, default: 0] += link.records.count
        }
        return counts
            .map { (domain: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var hasBackfillCandidates: Bool {
        allImages.contains { $0.detectedURLs.isEmpty && ($0.extractedText?.isEmpty == false) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
            
            if allLinks.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var toolbarView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Quick Links")
                    .font(.system(size: 28, weight: .bold))
                Text("\(allLinks.count) links across \(domainCounts.count) domains")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if hasBackfillCandidates {
                Button {
                    backfillExisting()
                } label: {
                    HStack(spacing: 6) {
                        if isBackfilling {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(isBackfilling ? "Scanning..." : "Scan for links")
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
                .disabled(isBackfilling)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                TextField("Filter links...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.secondary.opacity(0.15))
            )
            .frame(width: 260)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if !domainCounts.isEmpty && searchQuery.isEmpty {
                    domainSummarySection
                }
                
                linksListSection
            }
            .padding(24)
        }
    }
    
    private var domainSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Frequent")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(domainCounts.prefix(12), id: \.domain) { entry in
                    Button {
                        searchQuery = entry.domain
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.system(size: 11))
                            Text(entry.domain)
                                .font(.system(size: 12, weight: .medium))
                            Text("\(entry.count)")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.2))
                                )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.12))
                        )
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var linksListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(searchQuery.isEmpty ? "All Links" : "Results")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            LazyVStack(spacing: 8) {
                ForEach(filteredLinks) { link in
                    LinkRowView(occurrence: link)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "link")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            
            Text("No links detected yet")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Drop in screenshots containing URLs and we'll detect them automatically via OCR.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            if hasBackfillCandidates {
                Button {
                    backfillExisting()
                } label: {
                    Label("Scan existing screenshots", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor.opacity(0.15))
                        )
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(isBackfilling)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func backfillExisting() {
        guard !isBackfilling else { return }
        isBackfilling = true
        
        let candidates = allImages.filter { $0.detectedURLs.isEmpty && ($0.extractedText?.isEmpty == false) }
        
        Task {
            for record in candidates {
                guard let text = record.extractedText else { continue }
                let urls = ProcessingService.detectURLs(in: text)
                await MainActor.run {
                    record.detectedURLs = urls
                }
            }
            await MainActor.run {
                try? modelContext.save()
                isBackfilling = false
            }
        }
    }
    
    static func domain(for urlString: String) -> String? {
        guard let url = URL(string: urlString), let host = url.host else { return nil }
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }
}

private struct LinkRowView: View {
    let occurrence: QuickLinksView.LinkOccurrence
    @State private var isHovered = false
    
    var body: some View {
        Button {
            if let url = URL(string: occurrence.url) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayHost)
                        .font(.system(size: 13, weight: .semibold))
                    Text(occurrence.url)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                Text("\(occurrence.records.count) screenshot\(occurrence.records.count == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                
                Image(systemName: "arrow.up.forward.square")
                    .font(.system(size: 12))
                    .foregroundStyle(isHovered ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.07))
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                if let url = URL(string: occurrence.url) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Open URL", systemImage: "arrow.up.forward.app")
            }
            Button {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(occurrence.url, forType: .string)
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
        }
    }
    
    private var displayHost: String {
        QuickLinksView.domain(for: occurrence.url) ?? occurrence.url
    }
}

#Preview {
    QuickLinksView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
}

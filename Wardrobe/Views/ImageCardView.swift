//
//  ImageCardView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import AppKit

struct ImageCardView: View {
    let record: ImageRecord
    let similarity: Double?
    
    @State private var image: NSImage?
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailView
            
            HStack(spacing: 6) {
                if isHovered {
                    quickLookButton
                        .transition(.opacity)
                }
                if let similarity = similarity {
                    similarityBadge(similarity)
                }
            }
            .padding(8)
        }
        .onAppear(perform: loadImage)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var tagIndicator: some View {
        HStack(spacing: 3) {
            Image(systemName: "tag.fill")
                .font(.system(size: 8, weight: .bold))
            Text("\(record.customTags.count)")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.85))
        )
    }
    
    private var quickLookButton: some View {
        Button {
            QuickLookPreviewer.shared.preview(urls: [record.fileURL])
        } label: {
            Image(systemName: "eye")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.55))
                )
        }
        .buttonStyle(.plain)
        .help("Quick Look (Space)")
    }
    
    private var thumbnailView: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.15))
                
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                }
                
                // Hover overlay with filename
                if isHovered {
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom, spacing: 6) {
                            Text(timeAgoString(from: record.dateAdded))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.black.opacity(0.7))
                                )
                            Spacer()
                            if !record.customTags.isEmpty {
                                tagIndicator
                            }
                        }
                        .padding(8)
                    }
                } else if !record.customTags.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            tagIndicator
                        }
                        .padding(8)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .aspectRatio(4/3, contentMode: .fit)
    }
    
    private func similarityBadge(_ similarity: Double) -> some View {
        let percentage = Int(similarity * 100)
        let color: Color = {
            switch similarity {
            case 0.7...: return .green
            case 0.5..<0.7: return .orange
            default: return .red
            }
        }()
        
        return Text("\(percentage)%")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.9))
            )
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
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

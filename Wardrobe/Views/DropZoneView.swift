//
//  DropZoneView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let isProcessing: Bool
    let onDrop: ([NSItemProvider]) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: isDragging ? 2 : 1.5, dash: [8, 6])
                )
                .foregroundStyle(isDragging ? Color.accentColor : Color.secondary.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDragging ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.03))
                )
                .animation(.easeInOut(duration: 0.2), value: isDragging)
            
            VStack(spacing: 16) {
                if isProcessing {
                    ProgressView()
                        .controlSize(.large)
                    Text("Processing...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 56, weight: .regular))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isDragging ? [.blue, .purple] : [.secondary, .secondary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 6) {
                        Text("Drop screenshots here")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Drag and drop images to organize them with AI")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(40)
        }
        .onDrop(of: [.image], isTargeted: $isDragging) { providers in
            onDrop(providers)
            return true
        }
    }
}

#Preview {
    DropZoneView(isProcessing: false) { _ in }
        .frame(width: 500, height: 350)
        .padding(40)
        .preferredColorScheme(.dark)
}

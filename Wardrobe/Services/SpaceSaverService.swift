//
//  SpaceSaverService.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import AppKit

nonisolated enum CompressionLevel: String, CaseIterable, Identifiable, Sendable {
    case high       // minimal quality loss
    case balanced
    case max        // most aggressive
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .high: return "High Quality"
        case .balanced: return "Balanced"
        case .max: return "Max Compression"
        }
    }
    
    var subtitle: String {
        switch self {
        case .high: return "~30% smaller"
        case .balanced: return "~50% smaller"
        case .max: return "~70% smaller"
        }
    }
    
    var jpegQuality: Float {
        switch self {
        case .high: return 0.9
        case .balanced: return 0.7
        case .max: return 0.5
        }
    }
    
    var color: NSColor {
        switch self {
        case .high: return .systemBlue
        case .balanced: return .systemTeal
        case .max: return .systemIndigo
        }
    }
}

actor SpaceSaverService {
    static let shared = SpaceSaverService()
    
    private init() {}
    
    enum SpaceSaverError: Error {
        case imageLoadFailed
        case bitmapCreationFailed
        case jpegEncodingFailed
    }
    
    struct CompressionResult {
        let newURL: URL
        let oldBytes: Int64
        let newBytes: Int64
        var saved: Int64 { oldBytes - newBytes }
    }
    
    func compress(url: URL, level: CompressionLevel) async throws -> CompressionResult {
        let oldBytes = Self.fileSize(at: url)
        
        guard let data = try? Data(contentsOf: url),
              let nsImage = NSImage(data: data),
              let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw SpaceSaverError.imageLoadFailed
        }
        
        guard let jpegData = bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: NSNumber(value: level.jpegQuality)]
        ) else {
            throw SpaceSaverError.jpegEncodingFailed
        }
        
        // Only apply if it actually saves space
        guard Int64(jpegData.count) < oldBytes else {
            return CompressionResult(newURL: url, oldBytes: oldBytes, newBytes: oldBytes)
        }
        
        let newURL = url
            .deletingPathExtension()
            .appendingPathExtension("jpg")
        
        try jpegData.write(to: newURL, options: .atomic)
        
        if newURL != url {
            try? FileManager.default.removeItem(at: url)
        }
        
        return CompressionResult(
            newURL: newURL,
            oldBytes: oldBytes,
            newBytes: Int64(jpegData.count)
        )
    }
    
    static func fileSize(at url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path))
            .flatMap { $0[.size] as? Int64 } ?? 0
    }
}

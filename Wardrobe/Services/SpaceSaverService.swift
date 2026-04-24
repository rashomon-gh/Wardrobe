//
//  SpaceSaverService.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import AppKit

/// The visual quality and size reduction target for the Space Saver compression engine.
nonisolated enum CompressionLevel: String, CaseIterable, Identifiable, Sendable {
    /// Minimal quality loss. Target size reduction is ~30%.
    case high
    /// Noticeable size reduction while retaining good quality. Target size reduction is ~50%.
    case balanced
    /// Most aggressive compression algorithm. Target size reduction is ~70%.
    case max
    
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

/// A background actor responsible for identifying large images and aggressively compressing them
/// into JPEG format to save local disk space.
actor SpaceSaverService {
    /// The shared singleton instance.
    static let shared = SpaceSaverService()
    
    private init() {}
    
    enum SpaceSaverError: Error {
        case imageLoadFailed
        case bitmapCreationFailed
        case jpegEncodingFailed
    }
    
    /// The result of a successful compression operation.
    struct CompressionResult {
        /// The new absolute URL of the generated `.jpg` file.
        let newURL: URL
        /// The physical disk footprint of the original file in bytes.
        let oldBytes: Int64
        /// The physical disk footprint of the newly compressed file in bytes.
        let newBytes: Int64
        var saved: Int64 { oldBytes - newBytes }
    }
    
    /// Analyzes an image on disk and attempts to rewrite it using lossy JPEG compression.
    ///
    /// If the newly generated JPEG is larger than the original uncompressed file, the operation
    /// is discarded and the original file is kept to ensure no disk space is wasted.
    ///
    /// - Parameters:
    ///   - url: The physical file URL of the original image (usually PNG/TIFF).
    ///   - level: The targeted lossy compression setting.
    /// - Returns: A `CompressionResult` indicating how many bytes were saved and the new file URL.
    /// - Throws: `SpaceSaverError` if the bitmap cannot be generated or saved.
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

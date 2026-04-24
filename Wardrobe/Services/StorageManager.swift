//
//  StorageManager.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import UniformTypeIdentifiers

/// A background actor responsible for safely managing the local file system.
///
/// `StorageManager` ensures that images dropped into the app are safely copied
/// to the user's `~/Documents/Wardrobe/Images` directory without blocking the main UI thread.
actor StorageManager {
    /// The shared singleton instance.
    static let shared = StorageManager()
    
    private lazy var imagesDirectory: URL? = {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access Documents directory")
            return nil
        }
        
        let appDirectory = documentsURL.appendingPathComponent("Wardrobe/Images")
        
        do {
            try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
            print("Storage directory ready at: \(appDirectory.path)")
            return appDirectory
        } catch {
            print("Error creating storage directory: \(error)")
            return nil
        }
    }()
    
    private init() {}
    
    /// Asynchronously copies an image from an `NSItemProvider` (e.g., from a Drag and Drop event)
    /// into the app's secure sandbox storage directory.
    ///
    /// - Parameter itemProvider: The item provider delivering the image data.
    /// - Returns: The absolute URL where the image was permanently saved.
    /// - Throws: `StorageError` if the directory is missing or the system fails to copy the file.
    func saveImage(from itemProvider: NSItemProvider) async throws -> URL {
        guard let imagesDirectory else {
            throw StorageError.directoryNotAvailable
        }
        
        let destinationURL = nextDestinationURL(in: imagesDirectory)
        
        return try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let url = url else {
                    continuation.resume(throwing: StorageError.fileNotFound)
                    return
                }
                
                do {
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    continuation.resume(returning: destinationURL)
                } catch {
                    continuation.resume(throwing: StorageError.copyFailed(error))
                }
            }
        }
    }
    
    /// Copies an image from a known external URL (e.g., picked via a file dialog)
    /// into the app's secure sandbox storage directory.
    ///
    /// - Parameter url: The original absolute URL of the image.
    /// - Returns: The new absolute URL where the image was permanently saved.
    /// - Throws: `StorageError` if the directory is missing or the copy operation fails.
    func saveImage(from url: URL) throws -> URL {
        guard let imagesDirectory else {
            throw StorageError.directoryNotAvailable
        }
        
        let destinationURL = nextDestinationURL(in: imagesDirectory)
        try FileManager.default.copyItem(at: url, to: destinationURL)
        return destinationURL
    }
    
    /// Permanently deletes an image file from local disk storage.
    ///
    /// - Parameter url: The absolute URL of the file to remove.
    /// - Throws: Any `FileManager` error if the deletion fails (e.g., file not found).
    func deleteImage(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    private func nextDestinationURL(in directory: URL) -> URL {
        // Use UUID suffix to avoid collisions when saving multiple files in the same second
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueSuffix = UUID().uuidString.prefix(6)
        let filename = "screenshot_\(timestamp)_\(uniqueSuffix).png"
        return directory.appendingPathComponent(filename)
    }
}

enum StorageError: Error, LocalizedError {
    case directoryNotAvailable
    case fileNotFound
    case copyFailed(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .directoryNotAvailable:
            return "Storage directory is not available"
        case .fileNotFound:
            return "Image file not found"
        case .copyFailed(let error):
            return "Failed to copy image: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

//
//  StorageManager.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import UniformTypeIdentifiers

struct ImportedImage {
    let originalURL: URL
    let copiedURL: URL
    let sourceRelativePath: String
    let sourceTopLevelFolder: String?
}

/// A background actor responsible for safely managing the local file system.
///
/// `StorageManager` ensures that images dropped into the app are safely copied
/// to the configured image library directory without blocking the main UI thread.
actor StorageManager {
    /// The shared singleton instance.
    static let shared = StorageManager()

    private init() {}
    
    /// Asynchronously copies an image from an `NSItemProvider` (e.g., from a Drag and Drop event)
    /// into the app's secure sandbox storage directory.
    ///
    /// - Parameter itemProvider: The item provider delivering the image data.
    /// - Returns: The absolute URL where the image was permanently saved.
    /// - Throws: `StorageError` if the directory is missing or the system fails to copy the file.
    func saveImage(from itemProvider: NSItemProvider) async throws -> URL {
        let imagesDirectory = try resolveImageLibraryDirectory()
        
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
        let imagesDirectory = try resolveImageLibraryDirectory()
        
        let destinationURL = nextDestinationURL(in: imagesDirectory)
        try FileManager.default.copyItem(at: url, to: destinationURL)
        return destinationURL
    }
    
    /// Recursively imports all image files from a directory into the app-managed library,
    /// preserving each file's relative folder hierarchy under an import-specific root.
    ///
    /// - Parameter directoryURL: User-selected source directory.
    /// - Returns: Imported image descriptors including copied file URL and source folder metadata.
    /// - Throws: `StorageError` if directory enumeration or file copy fails.
    func importImages(fromDirectory directoryURL: URL) throws -> [ImportedImage] {
        let imagesDirectory = try resolveImageLibraryDirectory()
        
        let fileManager = FileManager.default
        let rootName = directoryURL.lastPathComponent
        let importFolderName = "import_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(6))_\(rootName)"
        let importRootURL = imagesDirectory.appendingPathComponent(importFolderName, isDirectory: true)
        try fileManager.createDirectory(at: importRootURL, withIntermediateDirectories: true, attributes: nil)
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .contentTypeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw StorageError.enumerationFailed(directoryURL.path)
        }
        
        var importedImages: [ImportedImage] = []
        
        for case let itemURL as URL in enumerator {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .contentTypeKey])
            if resourceValues.isDirectory == true {
                continue
            }
            
            guard let contentType = resourceValues.contentType, contentType.conforms(to: .image) else {
                continue
            }
            
            let relativePath = itemURL.path.replacingOccurrences(of: directoryURL.path + "/", with: "")
            let destinationURL = importRootURL.appendingPathComponent(relativePath)
            let destinationDirectory = destinationURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
            try fileManager.copyItem(at: itemURL, to: destinationURL)
            
            let relativeComponents = relativePath.split(separator: "/")
            let topLevelFolder: String?
            if relativeComponents.count > 1 {
                topLevelFolder = String(relativeComponents[0])
            } else {
                topLevelFolder = rootName
            }
            importedImages.append(
                ImportedImage(
                    originalURL: itemURL,
                    copiedURL: destinationURL,
                    sourceRelativePath: relativePath,
                    sourceTopLevelFolder: topLevelFolder
                )
            )
        }
        
        return importedImages
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

    private func resolveImageLibraryDirectory() throws -> URL {
        guard let imageLibraryURL = AppSettings.imageLibraryURL() else {
            throw StorageError.directoryNotAvailable
        }
        
        do {
            try FileManager.default.createDirectory(
                at: imageLibraryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return imageLibraryURL
        } catch {
            throw StorageError.copyFailed(error)
        }
    }
}

enum StorageError: Error, LocalizedError {
    case directoryNotAvailable
    case fileNotFound
    case copyFailed(Error)
    case enumerationFailed(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .directoryNotAvailable:
            return "Storage directory is not available"
        case .fileNotFound:
            return "Image file not found"
        case .copyFailed(let error):
            return "Failed to copy image: \(error.localizedDescription)"
        case .enumerationFailed(let path):
            return "Failed to enumerate directory: \(path)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

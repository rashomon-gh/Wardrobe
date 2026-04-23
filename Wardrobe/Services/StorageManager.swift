//
//  StorageManager.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import UniformTypeIdentifiers

actor StorageManager {
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
    
    func saveImage(from url: URL) throws -> URL {
        guard let imagesDirectory else {
            throw StorageError.directoryNotAvailable
        }
        
        let destinationURL = nextDestinationURL(in: imagesDirectory)
        try FileManager.default.copyItem(at: url, to: destinationURL)
        return destinationURL
    }
    
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

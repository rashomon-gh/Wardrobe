//
//  ImageRecord.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import SwiftData

/// The core data model representing an ingested image in Wardrobe.
///
/// `ImageRecord` acts as the single source of truth for a screenshot, storing
/// its physical file location alongside all extracted metadata (OCR text, 
/// vector embeddings, URLs, semantics, and user-defined tags).
@Model
final class ImageRecord {
    /// The primary key for the record.
    @Attribute(.unique) var id: UUID
    /// The physical name of the file on disk.
    var filename: String
    /// The absolute local file URL where the image is stored.
    var fileURL: URL
    /// The timestamp when the image was ingested.
    var dateAdded: Date
    /// The raw text extracted via Vision OCR, preserving columnar layout.
    var extractedText: String?
    /// The mathematical vector representation of the `extractedText` for semantic search.
    var textEmbedding: [Double]?
    /// User-assigned custom textual tags.
    var customTags: [String] = []
    /// User-assigned notes or descriptions.
    var notes: String?
    /// HTTP/HTTPS URLs detected within the OCR text via `NSDataDetector`.
    var detectedURLs: [String] = []
    /// Automated tags generated via Apple's Vision Image Classification framework.
    var smartTags: [String] = []
    /// Visual feature print binary data used for duplicate detection.
    var featurePrintData: Data?
    /// Semantic entities (dates, tracking numbers, organizations) extracted from the OCR text.
    var extractedEntities: [ExtractedEntity] = []
    
    /// Initializes a new Image Record with full metadata capabilities.
    /// - Parameters:
    ///   - id: Primary identifier.
    ///   - filename: File name.
    ///   - fileURL: Physical path URL.
    ///   - dateAdded: Ingestion timestamp.
    ///   - extractedText: OCR text preserving layout.
    ///   - textEmbedding: Semantic vector array.
    ///   - customTags: User tags.
    ///   - notes: User notes.
    ///   - detectedURLs: Parsed hyperlinks.
    ///   - smartTags: Vision image classifications.
    ///   - featurePrintData: Vision feature print for duplicate matching.
    ///   - extractedEntities: Parsed entities from NaturalLanguage/Foundation.
    init(
        id: UUID = UUID(),
        filename: String,
        fileURL: URL,
        dateAdded: Date = Date(),
        extractedText: String? = nil,
        textEmbedding: [Double]? = nil,
        customTags: [String] = [],
        notes: String? = nil,
        detectedURLs: [String] = [],
        smartTags: [String] = [],
        featurePrintData: Data? = nil,
        extractedEntities: [ExtractedEntity] = []
    ) {
        self.id = id
        self.filename = filename
        self.fileURL = fileURL
        self.dateAdded = dateAdded
        self.extractedText = extractedText
        self.textEmbedding = textEmbedding
        self.customTags = customTags
        self.notes = notes
        self.detectedURLs = detectedURLs
        self.smartTags = smartTags
        self.featurePrintData = featurePrintData
        self.extractedEntities = extractedEntities
    }
}

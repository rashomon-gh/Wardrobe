//
//  ImageRecord.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import SwiftData

@Model
final class ImageRecord {
    @Attribute(.unique) var id: UUID
    var filename: String
    var fileURL: URL
    var dateAdded: Date
    var extractedText: String?
    var textEmbedding: [Double]?
    var customTags: [String] = []
    var notes: String?
    var detectedURLs: [String] = []
    var smartTags: [String] = []
    var featurePrintData: Data?
    
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
        featurePrintData: Data? = nil
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
    }
}

//
//  ExtractedEntity.swift
//  Wardrobe
//
//  Created by AI Agent.
//

import Foundation
import SwiftData

/// A data structure representing a semantic entity extracted from OCR text.
///
/// `ExtractedEntity` models information parsed from images, such as tracking numbers,
/// organizations, people, dates, or transit info. It conforms to `Codable` to easily
/// serialize directly into a `SwiftData` store.
struct ExtractedEntity: Codable, Hashable, Identifiable {
    /// The unique identifier for this entity.
    var id: UUID
    /// The classification category of the entity (e.g., "Date", "Organization", "Tracking/Phone").
    var category: String
    /// The actual extracted string value.
    var value: String
    
    /// Initializes a new extracted entity.
    /// - Parameters:
    ///   - id: The unique identifier. Defaults to a new UUID.
    ///   - category: The classification category (e.g., "Organization").
    ///   - value: The matched string value.
    init(id: UUID = UUID(), category: String, value: String) {
        self.id = id
        self.category = category
        self.value = value
    }
}

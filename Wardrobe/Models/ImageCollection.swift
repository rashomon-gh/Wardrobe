//
//  ImageCollection.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import SwiftData
import SwiftUI

/// A user-created custom group of `ImageRecord`s.
///
/// `ImageCollection` allows users to manually organize their screenshots into distinct
/// customizable folders, complete with icons and color coding.
@Model
final class ImageCollection {
    /// The primary identifier for the collection.
    @Attribute(.unique) var id: UUID
    /// The user-defined display name.
    var name: String
    /// The SF Symbol icon name used in the UI.
    var iconName: String
    /// The hex string representing the collection's theme color (e.g., "#7B61FF").
    var colorHex: String
    /// The timestamp when the collection was created.
    var dateCreated: Date
    
    /// The list of images stored within this collection. Nullified if the collection is deleted.
    @Relationship(deleteRule: .nullify)
    var images: [ImageRecord] = []
    
    /// Initializes a new image collection.
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - name: The visible name of the collection.
    ///   - iconName: The SF Symbol name (default: "folder.fill").
    ///   - colorHex: The hexadecimal color string (default: "#7B61FF").
    ///   - dateCreated: Creation timestamp.
    ///   - images: Initial images to add.
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "folder.fill",
        colorHex: String = "#7B61FF",
        dateCreated: Date = Date(),
        images: [ImageRecord] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.dateCreated = dateCreated
        self.images = images
    }
    
    /// The SwiftUI `Color` representation of the collection's `colorHex`.
    var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }
}

extension Color {
    /// Initializes a SwiftUI `Color` from a hexadecimal string.
    /// - Parameter hex: A 6-character hex string (e.g., "#FF0000" or "FF0000").
    init?(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard sanitized.count == 6, let value = UInt32(sanitized, radix: 16) else { return nil }
        
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }
}

enum CollectionPalette {
    /// Pre-defined color pairs (name and hex) available for custom collections.
    static let presets: [(name: String, hex: String)] = [
        ("Purple", "#7B61FF"),
        ("Blue", "#3B82F6"),
        ("Teal", "#14B8A6"),
        ("Green", "#22C55E"),
        ("Orange", "#F97316"),
        ("Pink", "#EC4899"),
        ("Red", "#EF4444"),
        ("Slate", "#64748B")
    ]
    
    /// Pre-defined SF Symbol icon names available for custom collections.
    static let icons: [String] = [
        "folder.fill",
        "star.fill",
        "heart.fill",
        "bookmark.fill",
        "flag.fill",
        "briefcase.fill",
        "tag.fill",
        "sparkles",
        "lightbulb.fill",
        "paperplane.fill"
    ]
}

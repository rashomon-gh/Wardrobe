//
//  ImageCollection.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ImageCollection {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var dateCreated: Date
    
    @Relationship(deleteRule: .nullify)
    var images: [ImageRecord] = []
    
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
    
    var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }
}

extension Color {
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

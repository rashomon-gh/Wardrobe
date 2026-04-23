//
//  ExtractedEntity.swift
//  Wardrobe
//
//  Created by AI Agent.
//

import Foundation
import SwiftData

struct ExtractedEntity: Codable, Hashable, Identifiable {
    var id: UUID
    var category: String
    var value: String
    
    init(id: UUID = UUID(), category: String, value: String) {
        self.id = id
        self.category = category
        self.value = value
    }
}

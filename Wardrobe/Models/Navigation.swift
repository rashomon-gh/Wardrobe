//
//  Navigation.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation

enum NavigationSection: String, CaseIterable, Identifiable {
    case screenshots = "Screenshots"
    case collections = "Collections"
    case quickLinks = "Quick Links"
    case reOrganizer = "Re-Organizer"
    case spaceSaver = "Space Saver"
    case duplicateFinder = "Duplicate Finder"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .screenshots: return "photo.on.rectangle"
        case .collections: return "folder"
        case .quickLinks: return "link"
        case .reOrganizer: return "arrow.triangle.2.circlepath"
        case .spaceSaver: return "internaldrive"
        case .duplicateFinder: return "doc.on.doc"
        }
    }
    
    var category: NavigationCategory {
        switch self {
        case .screenshots, .collections, .quickLinks:
            return .library
        case .reOrganizer, .spaceSaver, .duplicateFinder:
            return .tools
        }
    }
}

enum NavigationCategory: String {
    case library = "LIBRARY"
    case tools = "TOOLS"
}

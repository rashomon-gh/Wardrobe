//
//  SmartCollection.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import SwiftUI

/// An enumeration of automatically computed, time-based image collections.
///
/// `SmartCollection` provides dynamic groupings (e.g., Today, Last 7 Days) that filter
/// `ImageRecord` objects based on their `dateAdded` property without manual user organization.
enum SmartCollection: String, CaseIterable, Identifiable {
    case today
    case yesterday
    case last7Days
    case last30Days
    
    var id: String { rawValue }
    
    /// The user-facing display title for the smart collection.
    var title: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        }
    }
    
    /// The SF Symbol icon associated with the time range.
    var iconName: String {
        switch self {
        case .today: return "sun.max.fill"
        case .yesterday: return "moon.fill"
        case .last7Days: return "calendar"
        case .last30Days: return "calendar.badge.clock"
        }
    }
    
    /// The gradient colors used to display the collection card in the UI.
    var gradient: [Color] {
        switch self {
        case .today: return [.orange, .pink]
        case .yesterday: return [.indigo, .purple]
        case .last7Days: return [.blue, .cyan]
        case .last30Days: return [.purple, .pink]
        }
    }
    
    /// Determines if a specific `Date` falls within this smart collection's time window.
    /// - Parameters:
    ///   - date: The date to check (usually the `dateAdded` of an `ImageRecord`).
    ///   - calendar: The calendar to use for calculations. Defaults to `.current`.
    ///   - now: The reference date for "today". Defaults to `Date()`.
    /// - Returns: `true` if the date falls within the time window.
    func matches(date: Date, calendar: Calendar = .current, now: Date = Date()) -> Bool {
        let startOfToday = calendar.startOfDay(for: now)
        let imageDay = calendar.startOfDay(for: date)
        
        switch self {
        case .today:
            return imageDay == startOfToday
        case .yesterday:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else {
                return false
            }
            return imageDay == yesterday
        case .last7Days:
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday) else {
                return false
            }
            return imageDay >= sevenDaysAgo && imageDay <= startOfToday
        case .last30Days:
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: startOfToday) else {
                return false
            }
            return imageDay >= thirtyDaysAgo && imageDay <= startOfToday
        }
    }
}

//
//  AppSettings.swift
//  Wardrobe
//
//  Created by Codex on 25/04/2026.
//

import Foundation

enum AppSettings {
    static let customImageLibraryPathKey = "customImageLibraryPath"
    private static let defaultImageLibraryRelativePath = "Wardrobe/Images"
    
    static func imageLibraryURL(
        fileManager: FileManager = .default,
        userDefaults: UserDefaults = .standard
    ) -> URL? {
        if let customPath = userDefaults.string(forKey: customImageLibraryPathKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !customPath.isEmpty {
            return URL(fileURLWithPath: customPath, isDirectory: true)
        }
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentsURL.appendingPathComponent(defaultImageLibraryRelativePath, isDirectory: true)
    }
    
    static func setCustomImageLibraryURL(
        _ url: URL?,
        userDefaults: UserDefaults = .standard
    ) {
        guard let url else {
            userDefaults.removeObject(forKey: customImageLibraryPathKey)
            return
        }
        
        userDefaults.set(url.standardizedFileURL.path, forKey: customImageLibraryPathKey)
    }
    
    static func customImageLibraryURL(userDefaults: UserDefaults = .standard) -> URL? {
        guard let customPath = userDefaults.string(forKey: customImageLibraryPathKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !customPath.isEmpty else {
            return nil
        }
        
        return URL(fileURLWithPath: customPath, isDirectory: true)
    }
}

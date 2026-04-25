//
//  WardrobeApp.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct WardrobeApp: App {
    let modelContainer: ModelContainer
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        do {
            let schema = Schema([ImageRecord.self, ImageCollection.self])
            modelContainer = try ModelContainer(for: schema, configurations: [])
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
        
        Task {
            await ProcessingService.shared.initialize()
            await SearchService.shared.initialize()
        }
    }
    
    var body: some Scene {
        Window("Wardrobe", id: "main-window") {
            MainContentView()
                .modelContainer(modelContainer)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 750)
        
        MenuBarExtra("Wardrobe", systemImage: "photo.on.rectangle.angled") {
            MenuBarPopoverView()
                .modelContainer(modelContainer)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.title == "Wardrobe" || $0.identifier?.rawValue == "main-window" }) {
                window.center()
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in NSApp.windows {
                if window.identifier?.rawValue == "main-window" {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    return true
                }
            }
        }
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

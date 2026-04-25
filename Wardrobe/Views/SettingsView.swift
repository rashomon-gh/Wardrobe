//
//  SettingsView.swift
//  Wardrobe
//
//  Created by Codex on 25/04/2026.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var customLibraryURL: URL? = AppSettings.customImageLibraryURL()
    @State private var showingError = false
    @State private var errorMessage: String?
    
    private var effectiveLibraryURL: URL? {
        AppSettings.imageLibraryURL()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("General")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Image Library Folder")
                    .font(.system(size: 13, weight: .semibold))
                Text("Wardrobe copies uploaded images into this folder.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Text(effectiveLibraryURL?.path ?? "Unavailable")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(.top, 2)
                
                HStack(spacing: 10) {
                    Button("Choose Folder...") {
                        chooseCustomLibraryFolder()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Use Default") {
                        AppSettings.setCustomImageLibraryURL(nil)
                        customLibraryURL = nil
                    }
                    .buttonStyle(.bordered)
                    .disabled(customLibraryURL == nil)
                }
                .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 520, height: 220)
        .alert("Unable to set folder", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error.")
        }
    }
    
    private func chooseCustomLibraryFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Select a folder to store imported screenshots."
        panel.directoryURL = effectiveLibraryURL
        
        let response = panel.runModal()
        guard response == .OK, let selectedURL = panel.url else { return }
        
        do {
            try FileManager.default.createDirectory(
                at: selectedURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            AppSettings.setCustomImageLibraryURL(selectedURL)
            customLibraryURL = selectedURL.standardizedFileURL
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    SettingsView()
}

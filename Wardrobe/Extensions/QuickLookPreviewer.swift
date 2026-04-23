//
//  QuickLookPreviewer.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import AppKit
import Quartz

@MainActor
final class QuickLookPreviewer: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookPreviewer()

    private var urls: [URL] = []

    private override init() {
        super.init()
    }

    func preview(urls: [URL], startIndex: Int = 0) {
        guard !urls.isEmpty else { return }
        self.urls = urls

        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()

        let clampedIndex = max(0, min(startIndex, urls.count - 1))
        panel.currentPreviewItemIndex = clampedIndex

        if panel.isVisible {
            panel.orderOut(nil)
        }
        panel.makeKeyAndOrderFront(nil)
    }

    // MARK: - QLPreviewPanelDataSource

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard urls.indices.contains(index) else { return nil }
        return urls[index] as NSURL
    }
}

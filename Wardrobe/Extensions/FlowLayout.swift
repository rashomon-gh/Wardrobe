//
//  FlowLayout.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(in: maxWidth, subviews: subviews)
        
        let totalHeight = rows.reduce(CGFloat.zero) { partial, row in
            partial + row.height
        } + CGFloat(max(0, rows.count - 1)) * rowSpacing
        
        let totalWidth = rows.map(\.width).max() ?? 0
        
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(in: bounds.width, subviews: subviews)
        
        var yOffset = bounds.minY
        for row in rows {
            var xOffset = bounds.minX
            for item in row.items {
                let size = item.size
                subviews[item.index].place(
                    at: CGPoint(x: xOffset, y: yOffset),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                xOffset += size.width + spacing
            }
            yOffset += row.height + rowSpacing
        }
    }
    
    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
    
    private func computeRows(in maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let additionalWidth = current.items.isEmpty ? size.width : current.width + spacing + size.width
            
            if additionalWidth > maxWidth && !current.items.isEmpty {
                rows.append(current)
                current = Row()
                current.items.append((index, size))
                current.width = size.width
                current.height = size.height
            } else {
                current.items.append((index, size))
                current.width = additionalWidth
                current.height = max(current.height, size.height)
            }
        }
        
        if !current.items.isEmpty {
            rows.append(current)
        }
        
        return rows
    }
}

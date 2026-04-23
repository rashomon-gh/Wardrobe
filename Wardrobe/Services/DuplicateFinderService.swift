//
//  DuplicateFinderService.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import Vision

actor DuplicateFinderService {
    static let shared = DuplicateFinderService()
    
    private init() {}
    
    struct DuplicateGroup: Identifiable {
        let id = UUID()
        /// Records sorted by preference - the first one is treated as the "keeper".
        let records: [ImageRecord]
        /// Max distance found among pairs in this group. Lower = more similar.
        let maxDistance: Float
    }
    
    /// Find groups of visually similar images. Threshold: 0..1, lower is stricter.
    func findDuplicateGroups(
        records: [ImageRecord],
        threshold: Float = 0.18
    ) async -> [DuplicateGroup] {
        let candidates: [(record: ImageRecord, observation: VNFeaturePrintObservation)] = records.compactMap { record in
            guard let data = record.featurePrintData,
                  let observation = ProcessingService.decodeFeaturePrint(data) else {
                return nil
            }
            return (record, observation)
        }
        
        guard candidates.count > 1 else { return [] }
        
        // Union-find clustering
        var parent = Array(0..<candidates.count)
        var maxDistanceSeen: [Int: Float] = [:]
        
        func find(_ x: Int) -> Int {
            var root = x
            while parent[root] != root { root = parent[root] }
            var current = x
            while parent[current] != root {
                let next = parent[current]
                parent[current] = root
                current = next
            }
            return root
        }
        
        func union(_ a: Int, _ b: Int, distance: Float) {
            let rootA = find(a)
            let rootB = find(b)
            if rootA == rootB {
                let existing = maxDistanceSeen[rootA] ?? 0
                maxDistanceSeen[rootA] = max(existing, distance)
                return
            }
            parent[rootA] = rootB
            let existingA = maxDistanceSeen.removeValue(forKey: rootA) ?? 0
            let existingB = maxDistanceSeen[rootB] ?? 0
            maxDistanceSeen[rootB] = max(existingA, existingB, distance)
        }
        
        for i in 0..<candidates.count {
            for j in (i + 1)..<candidates.count {
                var distance: Float = 0
                do {
                    try candidates[i].observation.computeDistance(&distance, to: candidates[j].observation)
                } catch {
                    continue
                }
                if distance <= threshold {
                    union(i, j, distance: distance)
                }
            }
        }
        
        var clusters: [Int: [Int]] = [:]
        for i in 0..<candidates.count {
            let root = find(i)
            clusters[root, default: []].append(i)
        }
        
        return clusters.values
            .filter { $0.count > 1 }
            .map { indices -> DuplicateGroup in
                let root = indices.first.map { find($0) } ?? 0
                let records = indices.map { candidates[$0].record }
                    .sorted { lhs, rhs in
                        let lhsSize = fileSize(for: lhs.fileURL)
                        let rhsSize = fileSize(for: rhs.fileURL)
                        if lhsSize != rhsSize { return lhsSize > rhsSize }
                        return lhs.dateAdded > rhs.dateAdded
                    }
                return DuplicateGroup(records: records, maxDistance: maxDistanceSeen[root] ?? 0)
            }
            .sorted { $0.records.count > $1.records.count }
    }
    
    nonisolated private func fileSize(for url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path))
            .flatMap { $0[.size] as? Int64 } ?? 0
    }
}

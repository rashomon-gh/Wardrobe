//
//  DuplicateFinderService.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import Vision

/// A background actor responsible for identifying visually identical or highly similar images.
///
/// `DuplicateFinderService` utilizes Apple's `Vision` framework to compare `VNFeaturePrintObservation`
/// binary data stored in `ImageRecord` objects. It groups duplicates using a Union-Find clustering algorithm
/// based on Euclidean distance thresholds.
actor DuplicateFinderService {
    /// The shared singleton instance.
    static let shared = DuplicateFinderService()
    
    private init() {}
    
    /// A model representing a cluster of visually similar images.
    struct DuplicateGroup: Identifiable {
        let id = UUID()
        /// Images sorted by preservation preference. The first element is the highest-quality
        /// or most recently added "keeper" image. Subsequent elements are candidates for deletion.
        let records: [ImageRecord]
        /// The maximum Euclidean distance found among pairs in this specific cluster.
        /// Lower values indicate higher visual similarity.
        let maxDistance: Float
    }
    
    /// Analyzes a dataset of images and clusters them into groups of visual duplicates.
    ///
    /// The algorithm calculates the geometric distance between `featurePrintData` vectors.
    /// It then applies a Union-Find clustering technique to group images that fall below the distance threshold.
    ///
    /// - Parameters:
    ///   - records: The dataset of `ImageRecord`s to analyze.
    ///   - threshold: The maximum allowed distance between feature prints to be considered a duplicate.
    ///                (Defaults to 0.18, where 0.0 is an exact pixel-perfect match).
    /// - Returns: An array of `DuplicateGroup` clusters, sorted by cluster size.
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
    
    /// Helper function to retrieve the physical file size on disk.
    ///
    /// - Parameter url: The absolute file URL.
    /// - Returns: The size of the file in bytes.
    nonisolated private func fileSize(for url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path))
            .flatMap { $0[.size] as? Int64 } ?? 0
    }
}

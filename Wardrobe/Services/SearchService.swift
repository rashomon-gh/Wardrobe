//
//  SearchService.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import SwiftData
import NaturalLanguage
import Accelerate

actor SearchService {
    static let shared = SearchService()
    
    private var embedding: NLEmbedding?
    private var isInitialized = false
    
    private init() {}
    
    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        Task.detached(priority: .background) {
            guard let model = NLEmbedding.sentenceEmbedding(for: .english) else {
                print("Failed to load embedding model for search: model is nil")
                return
            }
            await SearchService.shared.setEmbedding(model)
            print("SearchService embedding model loaded successfully")
        }
    }
    
    private func setEmbedding(_ model: NLEmbedding) {
        self.embedding = model
    }
    
    struct SearchResult {
        let record: ImageRecord
        let similarity: Double
    }
    
    func search(query: String, in modelContext: ModelContext, limit: Int = 20) async throws -> [SearchResult] {
        guard let embedding = embedding else {
            throw SearchError.embeddingNotAvailable
        }
        
        guard let queryVector = embedding.vector(for: query) else {
            throw SearchError.invalidQuery
        }
        
        var queryArray: [Double] = []
        queryArray.reserveCapacity(queryVector.count)
        
        for i in 0..<queryVector.count {
            queryArray.append(Double(queryVector[i]))
        }
        
        let fetchDescriptor = FetchDescriptor<ImageRecord>()
        let records = try modelContext.fetch(fetchDescriptor)
        
        let results = records.compactMap { record -> SearchResult? in
            guard let recordEmbedding = record.textEmbedding, !recordEmbedding.isEmpty else {
                return nil
            }
            
            let similarity = cosineSimilarity(query: queryArray, vector: recordEmbedding)
            return SearchResult(record: record, similarity: similarity)
        }
        
        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0 }
    }
    
    private func cosineSimilarity(query: [Double], vector: [Double]) -> Double {
        guard query.count == vector.count, !query.isEmpty else {
            return 0.0
        }
        
        var dotProduct = 0.0
        var normQuery = 0.0
        var normVector = 0.0
        
        for i in 0..<query.count {
            dotProduct += query[i] * vector[i]
            normQuery += query[i] * query[i]
            normVector += vector[i] * vector[i]
        }
        
        let magnitude = sqrt(normQuery) * sqrt(normVector)
        
        guard magnitude > 0 else {
            return 0.0
        }
        
        return dotProduct / magnitude
    }
}

enum SearchError: Error, LocalizedError {
    case embeddingNotAvailable
    case invalidQuery
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .embeddingNotAvailable:
            return "Embedding model is not available"
        case .invalidQuery:
            return "Invalid search query"
        case .unknown:
            return "An unknown search error occurred"
        }
    }
}

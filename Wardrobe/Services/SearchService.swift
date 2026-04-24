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

/// A background actor responsible for executing semantic searches across the image database.
///
/// `SearchService` utilizes Apple's `NaturalLanguage` framework to convert text queries
/// into numerical embeddings, and then performs cosine similarity math against the embeddings
/// stored in `ImageRecord` objects to find the most relevant matches.
actor SearchService {
    /// The shared singleton instance of the search service.
    static let shared = SearchService()
    
    private var embedding: NLEmbedding?
    private var isInitialized = false
    
    private init() {}
    
    /// Initializes the natural language embedding model asynchronously.
    ///
    /// This should be called early in the app lifecycle to ensure the model
    /// is loaded into memory before the user initiates a search.
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
    
    /// A structure representing a matched search result along with its relevancy score.
    struct SearchResult {
        /// The matched image record.
        let record: ImageRecord
        /// The cosine similarity score (1.0 = perfect match, 0.0 = completely unrelated).
        let similarity: Double
    }
    
    /// Executes a semantic search query against the provided context.
    ///
    /// - Parameters:
    ///   - query: The raw text string the user is searching for.
    ///   - modelContext: The SwiftData context used to fetch existing `ImageRecord`s.
    ///   - limit: The maximum number of results to return (defaults to 20).
    /// - Returns: An array of `SearchResult`, sorted by highest similarity first.
    /// - Throws: `SearchError` if the embedding model is unavailable or the query is invalid.
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
    
    /// Calculates the cosine similarity between two numerical vectors.
    ///
    /// - Parameters:
    ///   - query: The vectorized search query.
    ///   - vector: The pre-calculated vector for an `ImageRecord`.
    /// - Returns: A double between 0.0 and 1.0 representing mathematical similarity.
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

/// An enumeration of errors that can occur during the search process.
enum SearchError: Error, LocalizedError {
    /// Thrown when the `NLEmbedding` model fails to initialize or is not yet loaded.
    case embeddingNotAvailable
    /// Thrown when the search query cannot be successfully vectorized.
    case invalidQuery
    /// An unknown or unexpected error occurred.
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

//
//  ProcessingService.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import Foundation
import NaturalLanguage
import Vision

actor ProcessingService {
    static let shared = ProcessingService()
    
    private var embedding: NLEmbedding?
    private var isInitialized = false
    
    private init() {}
    
    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        Task.detached(priority: .background) {
            guard let model = NLEmbedding.sentenceEmbedding(for: .english) else {
                print("Failed to load embedding model: model is nil")
                return
            }
            await ProcessingService.shared.setEmbedding(model)
            print("NaturalLanguage embedding model loaded successfully")
        }
    }
    
    private func setEmbedding(_ model: NLEmbedding) {
        self.embedding = model
    }
    
    func processImage(at url: URL) async throws -> (text: String, embedding: [Double]?) {
        let extractedText = try await performOCR(at: url)
        let textEmbedding = try? await generateEmbedding(for: extractedText)
        return (extractedText, textEmbedding)
    }
    
    private func performOCR(at url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: ProcessingError.ocrFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: extractedText)
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            Task.detached(priority: .userInitiated) {
                do {
                    let handler = VNImageRequestHandler(url: url)
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: ProcessingError.ocrFailed(error))
                }
            }
        }
    }
    
    private func generateEmbedding(for text: String) async throws -> [Double] {
        guard let embedding = embedding else {
            throw ProcessingError.embeddingNotAvailable
        }
        
        guard !text.isEmpty else {
            return []
        }
        
        guard let vector = embedding.vector(for: text) else {
            throw ProcessingError.embeddingFailed(NSError(domain: "ProcessingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate vector"]))
        }
        
        var result: [Double] = []
        result.reserveCapacity(vector.count)
        
        for i in 0..<vector.count {
            result.append(Double(vector[i]))
        }
        
        return result
    }
}

enum ProcessingError: Error, LocalizedError {
    case ocrFailed(Error)
    case embeddingNotAvailable
    case embeddingFailed(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .ocrFailed(let error):
            return "OCR failed: \(error.localizedDescription)"
        case .embeddingNotAvailable:
            return "Embedding model is not available"
        case .embeddingFailed(let error):
            return "Failed to generate embedding: \(error.localizedDescription)"
        case .unknown:
            return "An unknown processing error occurred"
        }
    }
}

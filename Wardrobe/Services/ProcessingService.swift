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
    
    func processImage(at url: URL) async throws -> (text: String, embedding: [Double]?, urls: [String], smartTags: [String], featurePrint: Data?, entities: [ExtractedEntity]) {
        let extractedText = try await performOCR(at: url)
        let textEmbedding = try? await generateEmbedding(for: extractedText)
        let urls = Self.detectURLs(in: extractedText)
        let smartTags = (try? await classifyImage(at: url)) ?? []
        let featurePrint = try? await generateFeaturePrint(at: url)
        let entities = Self.extractEntities(from: extractedText)
        return (extractedText, textEmbedding, urls, smartTags, featurePrint, entities)
    }
    
    func generateFeaturePrint(at url: URL) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateImageFeaturePrintRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: ProcessingError.featurePrintFailed(error))
                    return
                }
                
                guard let observation = (request.results as? [VNFeaturePrintObservation])?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: true)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: ProcessingError.featurePrintFailed(error))
                }
            }
            
            Task.detached(priority: .userInitiated) {
                do {
                    let handler = VNImageRequestHandler(url: url)
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: ProcessingError.featurePrintFailed(error))
                }
            }
        }
    }
    
    nonisolated static func decodeFeaturePrint(_ data: Data) -> VNFeaturePrintObservation? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: data)
    }
    
    func classifyImage(at url: URL, maxTags: Int = 6, minConfidence: Float = 0.3) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: ProcessingError.classificationFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let tags = observations
                    .filter { $0.confidence >= minConfidence }
                    .prefix(maxTags)
                    .map { Self.formatTag($0.identifier) }
                
                continuation.resume(returning: Array(tags))
            }
            
            Task.detached(priority: .userInitiated) {
                do {
                    let handler = VNImageRequestHandler(url: url)
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: ProcessingError.classificationFailed(error))
                }
            }
        }
    }
    
    private static func formatTag(_ identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).capitalized + $0.dropFirst() }
            .joined(separator: " ")
    }
    
    static func detectURLs(in text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        
        var seen: Set<String> = []
        var urls: [String] = []
        for match in matches {
            guard let url = match.url else { continue }
            // Drop mailto/tel, keep real web-style URLs
            guard let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else { continue }
            let absolute = url.absoluteString
            if seen.insert(absolute).inserted {
                urls.append(absolute)
            }
        }
        return urls
    }
    
    static func extractEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, let category = mapNLTaggerTagToCategory(tag) {
                let value = String(text[tokenRange])
                entities.append(ExtractedEntity(category: category, value: value))
            }
            return true
        }
        
        let types: NSTextCheckingResult.CheckingType = [.date, .phoneNumber, .transitInformation]
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            for match in matches {
                guard let range = Range(match.range, in: text) else { continue }
                let value = String(text[range])
                
                if match.resultType == .date, match.date != nil {
                    entities.append(ExtractedEntity(category: "Date", value: value))
                } else if match.resultType == .phoneNumber {
                    if value.filter({ $0.isNumber }).count >= 10 {
                        entities.append(ExtractedEntity(category: "Tracking/Phone", value: value))
                    } else {
                        entities.append(ExtractedEntity(category: "Phone", value: value))
                    }
                } else if match.resultType == .transitInformation {
                    entities.append(ExtractedEntity(category: "Transit Info", value: value))
                }
            }
        }
        
        var uniqueEntities: [ExtractedEntity] = []
        var seen = Set<String>()
        for entity in entities {
            let key = "\(entity.category):\(entity.value)"
            if !seen.contains(key) {
                seen.insert(key)
                uniqueEntities.append(entity)
            }
        }
        
        return uniqueEntities
    }
    
    private static func mapNLTaggerTagToCategory(_ tag: NLTag) -> String? {
        switch tag {
        case .organizationName: return "Organization"
        case .personalName: return "Person"
        case .placeName: return "Place"
        default: return nil
        }
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
    case classificationFailed(Error)
    case featurePrintFailed(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .ocrFailed(let error):
            return "OCR failed: \(error.localizedDescription)"
        case .embeddingNotAvailable:
            return "Embedding model is not available"
        case .embeddingFailed(let error):
            return "Failed to generate embedding: \(error.localizedDescription)"
        case .classificationFailed(let error):
            return "Image classification failed: \(error.localizedDescription)"
        case .featurePrintFailed(let error):
            return "Feature print generation failed: \(error.localizedDescription)"
        case .unknown:
            return "An unknown processing error occurred"
        }
    }
}

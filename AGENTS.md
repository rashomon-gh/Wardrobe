# Wardrobe - AI Agent Development Guide

This document provides comprehensive guidance for coding agents working on the Wardrobe project, a macOS semantic screenshot organizer.

## Project Overview

**Wardrobe** is a privacy-first, local macOS menubar application that organizes and searches screenshots using Optical Character Recognition (OCR) and semantic embeddings. All processing happens on-device with zero external API calls.

### Core Values
- **Privacy-First**: All data stored locally, no cloud processing
- **Performance**: Optimized for macOS using native frameworks
- **Simplicity**: Clean, maintainable code with clear separation of concerns
- **Accessibility**: Intuitive UI with keyboard shortcuts and visual feedback

## Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (macOS 14+)
- **Data Persistence**: SwiftData
- **OCR**: Vision Framework (`VNRecognizeTextRequest`)
- **Semantic Embeddings**: NaturalLanguage Framework (`NLEmbedding.sentenceEmbedding`)
- **Vector Operations**: Accelerate framework (for cosine similarity)
- **Concurrency**: Swift actors and async/await

## Project Structure

```
Wardrobe/
├── Models/
│   ├── ImageRecord.swift          # SwiftData model for image metadata
│   └── Navigation.swift           # Navigation section enums
├── Services/
│   ├── StorageManager.swift       # File operations and image storage (actor)
│   ├── ProcessingService.swift    # OCR and embedding generation (actor)
│   └── SearchService.swift        # Semantic search with cosine similarity (actor)
├── Views/
│   ├── MainContentView.swift      # Main app window with sidebar
│   ├── MenuBarPopoverView.swift   # Menubar popup interface
│   ├── GalleryView.swift          # Main gallery with search and grid
│   ├── SearchBarView.swift        # Search input components
│   ├── DropZoneView.swift         # Drag-and-drop area
│   ├── ImageCardView.swift        # Individual image card
│   └── SidebarView.swift          # Navigation sidebar
├── Extensions/
│   └── QuickLookExtension.swift   # Image preview functionality
└── WardrobeApp.swift              # App entry point
```

## Architecture Patterns

### Data Flow
1. **Ingestion**: User drags images into menubar drop zone
2. **Storage**: Images saved to `~/Documents/Wardrobe/Images/`
3. **Processing**: Vision framework extracts text, NaturalLanguage generates embeddings
4. **Persistence**: Metadata, OCR text, and embeddings stored in SwiftData
5. **Retrieval**: Search queries vectorized and compared using cosine similarity

### Service Layer (Actors)
All services are implemented as Swift actors to ensure thread-safe access:

- **StorageManager**: Handles file I/O operations
- **ProcessingService**: Manages OCR and embedding generation
- **SearchService**: Performs semantic search with vector comparisons

### View Layer
- SwiftUI views with `@Environment(\.modelContext)` for data access
- Reactive state management using `@State` and `@Binding`
- Async operations with `Task` and `Task.detached`
- Preview support for all views with `#Preview` macro

### Data Models
- SwiftData `@Model` classes for persistence
- Clear separation between domain models and view models
- Use of `@Attribute(.unique)` for primary keys

## Coding Guidelines

### Swift Concurrency

**Always use actors for services:**
```swift
actor StorageManager {
    static let shared = StorageManager()
    private init() {}
    
    func saveImage(from url: URL) throws -> URL {
        // Thread-safe implementation
    }
}
```

**Prefer async/await over completion handlers:**
```swift
// Good
func processImage(at url: URL) async throws -> (text: String, embedding: [Double]?) {
    let extractedText = try await performOCR(at: url)
    let embedding = try? await generateEmbedding(for: extractedText)
    return (extractedText, embedding)
}

// Avoid
func processImage(at url: URL, completion: (Result<String, Error>) -> Void) {
    // Old completion handler style
}
```

**Use Task.detached for background work:**
```swift
Task.detached(priority: .userInitiated) {
    // Background processing
}
```

### SwiftUI Best Practices

**Use `@Environment(\.modelContext)` for data access:**
```swift
struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageRecord.dateAdded, order: .reverse) private var allImages: [ImageRecord]
}
```

**Implement proper error handling with alerts:**
```swift
@State private var errorMessage: String?
@State private var showingError = false

.alert("Error", isPresented: $showingError) {
    Button("OK", role: .cancel) { }
} message: {
    if let errorMessage = errorMessage {
        Text(errorMessage)
    }
}
```

**Use `@ViewBuilder` for conditional views:**
```swift
@ViewBuilder
private var content: some View {
    if isLoading {
        ProgressView()
    } else if items.isEmpty {
        EmptyView()
    } else {
        ScrollView { /* content */ }
    }
}
```

### Error Handling

**Define custom error types:**
```swift
enum StorageError: Error, LocalizedError {
    case directoryNotAvailable
    case fileNotFound
    case copyFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .directoryNotAvailable:
            return "Storage directory is not available"
        // ... other cases
        }
    }
}
```

**Use throwing functions for error propagation:**
```swift
func saveImage(from url: URL) throws -> URL {
    guard let imagesDirectory else {
        throw StorageError.directoryNotAvailable
    }
    // ... implementation
}
```

### File Organization

**Group related files by feature:**
- Models in `Models/` directory
- Services in `Services/` directory
- Views in `Views/` directory
- Extensions in `Extensions/` directory

**Keep files focused:**
- Each file should have a single, clear responsibility
- Maximum 300-400 lines per file
- Use extensions for organization within files

### Naming Conventions

**Use descriptive names:**
- Variables: `camelCase` (e.g., `searchResults`)
- Functions: `camelCase` starting with verb (e.g., `performSearch`, `handleDrop`)
- Types: `PascalCase` (e.g., `ImageRecord`, `StorageManager`)
- Constants: `lowerCamelCase` for local, `UPPER_CASE` for global

**Avoid abbreviations:**
```swift
// Good
let extractedText = try await performOCR(at: url)

// Avoid
let txt = try await ocr(at: url)
```

## Performance Guidelines

### Image Loading
- Load images lazily using `Task.detached`
- Cache loaded images in `@State`
- Use placeholder while loading:

```swift
@State private var image: NSImage?

private func loadImage() {
    guard image == nil else { return }
    let url = record.fileURL
    
    Task.detached(priority: .userInitiated) {
        guard let data = try? Data(contentsOf: url),
              let nsImage = NSImage(data: data) else { return }
        await MainActor.run {
            self.image = nsImage
        }
    }
}
```

### Search Optimization
- Limit search results (default: 20-30)
- Use efficient data structures
- Debounce search input:

```swift
.onChange(of: searchQuery) { _, _ in
    // Debounce logic
    Task {
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
        performSearch()
    }
}
```

### Vector Operations
- Use Accelerate framework for efficient computations
- Pre-compute embeddings and store in SwiftData
- Reuse embedding models (singleton pattern)

## Testing Considerations

### Unit Tests
- Test service methods in isolation
- Mock dependencies for file I/O
- Test error handling paths

### Integration Tests
- Test full data flow (ingest → process → search)
- Verify SwiftData persistence
- Test UI interactions

### Preview Support
- Provide `#Preview` macros for all views
- Use in-memory model containers for previews:

```swift
#Preview {
    GalleryView()
        .modelContainer(for: ImageRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
}
```

## Privacy and Security

### Data Handling
- Never send data to external APIs
- Store all data locally in user's Documents directory
- Use standard macOS file permissions
- Clear sensitive data from memory when possible

### File Storage
- Store images in `~/Documents/Wardrobe/Images/`
- Use unique filenames with timestamps and UUIDs
- Provide cleanup functionality for deleted records

## Common Tasks

### Adding a New Service
1. Create Swift actor in `Services/` directory
2. Implement singleton pattern with `static let shared`
3. Use async/await for all public methods
4. Define custom error type
5. Initialize in `WardrobeApp.swift` init

### Adding a New View
1. Create SwiftUI view in `Views/` directory
2. Use `@Environment(\.modelContext)` for data access
3. Implement `@Query` for data fetching
4. Add `#Preview` macro
5. Wire up in parent view or navigation

### Adding a New Model Property
1. Update `@Model` class in `Models/`
2. Consider migration strategy if needed
3. Update all views using the model
4. Update service methods if processing affected

### Implementing Search
1. Use `SearchService.shared.search()`
2. Handle errors gracefully
3. Show loading state during search
4. Display results with similarity scores
5. Handle empty results case

## Platform-Specific Guidelines

### macOS 14+ Features
- Use `MenuBarExtra` for menubar integration
- Leverage `NavigationSplitView` for sidebar layouts
- Use `NSWorkspace` for file system operations
- Implement `QuickLook` for image previews

### Accessibility
- Provide keyboard shortcuts
- Support VoiceOver with appropriate labels
- Use semantic colors and contrast ratios
- Add `.help()` modifiers for tooltips

## Build and Run

### Requirements
- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9+

### Building
```bash
# Open in Xcode
open Wardrobe.xcodeproj

# Or build from command line
xcodebuild -project Wardrobe.xcodeproj -scheme Wardrobe build
```

### Running
- Press ⌘R in Xcode
- App appears in menubar with photo icon
- Main window opens automatically on first launch

## Debugging Tips

### Common Issues
- **Embedding model not loading**: Check NaturalLanguage framework initialization
- **OCR failing**: Verify image format and Vision framework permissions
- **Search returning empty**: Ensure embeddings are generated and stored
- **File not found**: Check `~/Documents/Wardrobe/Images/` directory

### Logging
- Use `print()` for debug output
- Check Xcode console for error messages
- Verify file paths and permissions

### Performance Profiling
- Use Instruments for profiling
- Check memory usage with large image sets
- Monitor embedding generation time
- Profile search queries

## Future Enhancements (Not Yet Implemented)

The following features are planned but not yet implemented. When working on these, follow existing patterns:

- **Collections**: Organize screenshots into custom folders
- **Quick Links**: Save and organize important links
- **Re-Organizer**: Auto-organize screenshots with AI
- **Space Saver**: Manage disk space usage
- **Duplicate Finder**: Find and remove duplicate screenshots

## Contribution Guidelines

### Code Review Checklist
- [ ] Follows naming conventions
- [ ] Uses async/await properly
- [ ] Handles errors appropriately
- [ ] Includes preview support
- [ ] Tests edge cases
- [ ] Maintains privacy principles
- [ ] Performs efficiently
- [ ] Documents complex logic

### Commit Messages
- Use clear, descriptive messages
- Start with verb (e.g., "Add", "Fix", "Update")
- Include context for why change was made
- Keep under 72 characters for first line

## Resources

### Apple Documentation
- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [NaturalLanguage Framework](https://developer.apple.com/documentation/naturallanguage)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)

### Internal References
- `README.md` - Project overview and usage
- Code comments for implementation details
- Swift documentation comments (`///`) for API documentation

## Contact

For questions or clarifications about this guide, refer to the project README.md or existing code patterns.

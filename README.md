# Wardrobe - macOS Semantic Screenshot Organizer

A privacy-first, local macOS menubar application that organizes and searches screenshots using Optical Character Recognition (OCR) and semantic embeddings. All processing happens on-device with zero external API calls.

## Features

- **Drag & Drop Integration**: Simply drag screenshots into the menubar app to organize them
- **OCR Processing**: Automatically extracts text from images using Apple's Vision framework
- **Semantic Search**: Natural language search powered by Apple's NaturalLanguage framework
- **Privacy-First**: All data stored locally, no cloud processing
- **Quick Look Preview**: Click on images to preview them in full size

## Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (macOS 14+)
- **Data Persistence**: SwiftData
- **OCR**: Vision Framework (VNRecognizeTextRequest)
- **Semantic Embeddings**: NaturalLanguage Framework (NLEmbedding)
- **Search Algorithm**: Cosine Similarity for vector comparisons

## Architecture

### Data Flow

1. **Ingestion**: User drags images into the menubar drop zone
2. **Storage**: Images are saved to `~/Documents/Wardrobe/Images/`
3. **Processing**: 
   - Vision framework extracts text from images
   - NaturalLanguage framework generates semantic embeddings
4. **Persistence**: Metadata, OCR text, and embeddings stored in SwiftData
5. **Retrieval**: Search queries are vectorized and compared using cosine similarity

### Core Components

#### Models
- `ImageRecord`: SwiftData model storing image metadata, OCR text, and embeddings

#### Services
- `StorageManager`: Handles file operations and image storage
- `ProcessingService`: Manages OCR and embedding generation
- `SearchService`: Performs semantic search with cosine similarity

#### Views
- `MenuBarView`: Main menubar interface
- `SearchBarView`: Search input field
- `DropZoneView`: Drag-and-drop area for images
- `ImageGridView`: Displays search results in a grid
- `ImageThumbnailView`: Individual image preview with similarity score

## Usage

1. Launch the app - it appears in the macOS menubar
2. Drag and drop screenshots onto the drop zone
3. The app automatically processes each image (OCR + embedding generation)
4. Type a natural language query to search through your images
5. Click on any result to preview the full image

## Search Examples

- "database schema"
- "error message about timeout"
- "pricing page with plans"
- "dashboard showing analytics"
- "API documentation"

## Installation

1. Clone the repository
2. Open `Wardrobe.xcodeproj` in Xcode
3. Build and run (⌘R)

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later

## Development Notes

- The app runs in the background/menubar (LSUIElement = YES)
- All ML processing uses Apple's native frameworks (Vision, NaturalLanguage)
- Concurrency is handled using Swift's async/await and actors
- Vector operations are optimized for performance

## Privacy

- Zero external API calls
- All data stored locally on your Mac
- No internet connection required for processing
- Images stored in standard Documents directory

## License

Created by Shawon Ashraf

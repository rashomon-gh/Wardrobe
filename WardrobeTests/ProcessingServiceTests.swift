import XCTest
@testable import Wardrobe

final class ProcessingServiceTests: XCTestCase {
    
    func testDetectURLs_withValidURLs() {
        let text = "Here is a repository: https://github.com/rashomon-gh/Wardrobe and a website http://apple.com."
        let urls = ProcessingService.detectURLs(in: text)
        
        XCTAssertEqual(urls.count, 2)
        XCTAssertTrue(urls.contains("https://github.com/rashomon-gh/Wardrobe"))
        XCTAssertTrue(urls.contains("http://apple.com"))
    }
    
    func testDetectURLs_ignoresNonWebSchemes() {
        let text = "Contact via mailto:hello@wardrobe.app or call tel:+123456789. Also see https://wardrobe.app"
        let urls = ProcessingService.detectURLs(in: text)
        
        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls.first, "https://wardrobe.app")
    }
    
    func testExtractEntities_identifiesDates() {
        let text = "Your delivery is scheduled for October 25, 2024 at 10:00 AM."
        let entities = ProcessingService.extractEntities(from: text)
        
        let dates = entities.filter { $0.category == "Date" }
        XCTAssertFalse(dates.isEmpty)
    }
    
    func testExtractEntities_identifiesLongNumbersAsTracking() {
        // NSDataDetector often matches long numeric strings (like tracking numbers) as phone numbers.
        // Our logic relabels >= 10 digits as "Tracking/Phone".
        let text = "Your tracking number is 10002930492813 or 1-800-123-4567."
        let entities = ProcessingService.extractEntities(from: text)
        
        let tracking = entities.filter { $0.category == "Tracking/Phone" }
        XCTAssertFalse(tracking.isEmpty)
    }
    
    func testExtractEntities_identifiesOrganizations() {
        let text = "Receipt from Apple Inc. and GitHub."
        let entities = ProcessingService.extractEntities(from: text)
        
        let orgs = entities.filter { $0.category == "Organization" }
        XCTAssertTrue(orgs.contains(where: { $0.value.contains("Apple") || $0.value.contains("GitHub") }))
    }
    
    func testExtractEntities_removesDuplicates() {
        let text = "Apple is located in Cupertino. I repeat, Apple is in Cupertino."
        let entities = ProcessingService.extractEntities(from: text)
        
        let orgs = entities.filter { $0.category == "Organization" && $0.value.contains("Apple") }
        // Should only have 1 instance due to de-duplication
        XCTAssertEqual(orgs.count, 1)
    }
}

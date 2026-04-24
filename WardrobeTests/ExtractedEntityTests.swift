import XCTest
@testable import Wardrobe

final class ExtractedEntityTests: XCTestCase {
    
    func testEntityInitialization() {
        let id = UUID()
        let entity = ExtractedEntity(id: id, category: "Organization", value: "Apple")
        
        XCTAssertEqual(entity.id, id)
        XCTAssertEqual(entity.category, "Organization")
        XCTAssertEqual(entity.value, "Apple")
    }
    
    func testEntityCodable() throws {
        let entity = ExtractedEntity(category: "Person", value: "Craig Federighi")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entity)
        
        let decoder = JSONDecoder()
        let decodedEntity = try decoder.decode(ExtractedEntity.self, from: data)
        
        XCTAssertEqual(entity.id, decodedEntity.id)
        XCTAssertEqual(entity.category, decodedEntity.category)
        XCTAssertEqual(entity.value, decodedEntity.value)
    }
}

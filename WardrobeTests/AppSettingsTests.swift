import XCTest
@testable import Wardrobe

final class AppSettingsTests: XCTestCase {
    func testCompressedImageLibraryURL_usesDefaultLibraryPath() {
        let suiteName = "AppSettingsTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        guard let imageLibraryURL = AppSettings.imageLibraryURL(userDefaults: userDefaults) else {
            XCTFail("Expected default image library URL")
            return
        }
        guard let compressedURL = AppSettings.compressedImageLibraryURL(userDefaults: userDefaults) else {
            XCTFail("Expected compressed image library URL")
            return
        }

        XCTAssertEqual(compressedURL, imageLibraryURL.appendingPathComponent("Compressed", isDirectory: true))
    }

    func testCompressedImageLibraryURL_usesCustomLibraryPath() {
        let suiteName = "AppSettingsTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("wardrobe-library-\(UUID().uuidString)", isDirectory: true)
        AppSettings.setCustomImageLibraryURL(temporaryDirectory, userDefaults: userDefaults)

        guard let compressedURL = AppSettings.compressedImageLibraryURL(userDefaults: userDefaults) else {
            XCTFail("Expected compressed image library URL")
            return
        }

        XCTAssertEqual(compressedURL, temporaryDirectory.appendingPathComponent("Compressed", isDirectory: true))
    }
}

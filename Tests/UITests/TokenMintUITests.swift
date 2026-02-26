import XCTest

final class TokenMintUITests: XCTestCase {
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }
}

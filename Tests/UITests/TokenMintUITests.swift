import XCTest

final class TokenMintUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    // MARK: - Launch

    func testAppLaunches() throws {
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }

    func testNavigationTitleIsTokenMint() throws {
        let navBar = app.navigationBars["TokenMint"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
    }

    // MARK: - Token List Toolbar

    func testTokenListShowsAddButton() throws {
        let addButton = app.buttons["add_token_button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    }

    func testAddMenuShowsOptions() throws {
        let addButton = app.buttons["add_token_button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Menu should show "Add Manually" and "Scan QR Code"
        let addManually = app.buttons["Add Manually"]
        XCTAssertTrue(addManually.waitForExistence(timeout: 3))
    }

    func testAddManuallyNavigatesToForm() throws {
        let addButton = app.buttons["add_token_button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let addManually = app.buttons["Add Manually"]
        XCTAssertTrue(addManually.waitForExistence(timeout: 3))
        addManually.tap()

        // Should see the issuer field on the add token screen
        let issuerField = app.textFields["issuer_field"]
        XCTAssertTrue(issuerField.waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["secret_field"].exists)
    }

    // MARK: - Settings

    func testSettingsGearNavigatesToSettings() throws {
        // Settings is accessed via gear icon in toolbar, not a tab bar
        let gearButton = app.buttons["settings_button"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5))
        gearButton.tap()

        // Should see haptic toggle in settings (biometric may be hidden in simulator)
        let toggle = app.switches["haptic_toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
    }

    // MARK: - Empty State

    func testEmptyStateShowsPlaceholder() throws {
        // With no tokens, should see "No Tokens Yet" placeholder
        let placeholder = app.staticTexts["No Tokens Yet"]
        XCTAssertTrue(placeholder.waitForExistence(timeout: 5))
    }
}

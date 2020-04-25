//
//  SnapshotTests.swift
//  GhostWriterUITests
//
//  Created by Jacob Sokora on 4/24/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import XCTest

class SnapshotTests: XCTestCase {

	let app = XCUIApplication()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
		setupSnapshot(app)
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testSnapshots() {
		guard let credentialFile = Bundle(for: type(of: self)).path(forResource: "Credentials", ofType: "plist"), let credentials = NSDictionary(contentsOfFile: credentialFile), let blogURL = credentials["BLOG_URL"] as? String, let username = credentials["USERNAME"] as? String, let password = credentials["PASSWORD"] as? String else {
			return XCTFail("Please include a credential file with access information for a blog")
		}

		XCTAssert(!blogURL.starts(with: "https://"), "Blog url should omit https:// for test, this is due to xc ui tests being annoying")

		let exists = NSPredicate(format: "exists == 1")

		let setupButton = app.buttons["setup"]
		//Tap the setup button, either signing out or going to the sign in screen
		if setupButton.isHittable {
			setupButton.tap()
		}
		//If the previous action signed us out, go to the sign in screen
		if setupButton.isHittable {
			setupButton.tap()
		}

		let blogURLField = app.textFields["blogURL"]
		expectation(for: exists, evaluatedWith: blogURLField, handler: nil)
		waitForExpectations(timeout: 5, handler: nil)
		blogURLField.typeTextSlowly(blogURL, returnAfter: true)

		let usernameField = app.textFields["username"]
		let passwordField = app.secureTextFields["password"]
		expectation(for: exists, evaluatedWith: usernameField, handler: nil)
		waitForExpectations(timeout: 10, handler: nil)
		snapshot("Sign in")
		usernameField.tap()
		usernameField.typeTextSlowly(username)
		passwordField.tap()
		passwordField.typeTextSlowly(password)
		app.buttons["signin"].tap()

		expectation(for: exists, evaluatedWith: setupButton, handler: nil)
		waitForExpectations(timeout: 5, handler: nil)

		snapshot("Posts")

		app.tables.element(boundBy: 0).cells.element(boundBy: 0).tap()

		sleep(5)

		snapshot("Editor")

		app.segmentedControls.element(boundBy: 0).buttons.element(boundBy: 1).tap()

		sleep(5)

		snapshot("Preview")

		app.buttons["options"].tap()

		expectation(for: exists, evaluatedWith: app.images["image"], handler: nil)
		waitForExpectations(timeout: 5, handler: nil)
		sleep(5)

		snapshot("Options")
	}

}

extension XCUIElement {

	func typeTextSlowly(_ string: String, returnAfter: Bool = false) {
		self.tap()
		for letter in string {
			self.typeText("\(letter)")
		}
		if returnAfter {
			self.typeText(XCUIKeyboardKey.return.rawValue)
		}
	}
}

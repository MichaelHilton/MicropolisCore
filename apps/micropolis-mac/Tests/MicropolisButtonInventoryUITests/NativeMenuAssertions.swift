import XCTest

/// Native menu marks are not exposed by XCTest's value/selected fields.
/// Inspect the visible mark gutter in the standard XCTest screenshot.
enum NativeMenuAssertions {
    static func assertMarked(
        _ expected: Bool,
        title: String,
        identifier: String? = nil,
        under rootIdentifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let root = app.descendants(matching: .any).matching(identifier: rootIdentifier).firstMatch
        let item = root.descendants(matching: .menuItem).matching(identifier: identifier ?? title).firstMatch
        XCTAssertTrue(item.exists, "Missing menu item " + title, file: file, line: line)
        XCTContext.runActivity(named: "Menu checkmark: " + title) { activity in
            do {
                let evidence = try MenuCheckmarkPixels.inspect(item)
                print("MENU_MARK \(title) expected=\(expected): \(evidence)")
                let attachment = XCTAttachment(image: evidence.crop)
                attachment.name = title + (expected ? " checked" : " unchecked")
                attachment.lifetime = .keepAlways
                activity.add(attachment)
                XCTAssertEqual(evidence.isMarked, expected, evidence.description, file: file, line: line)
            } catch {
                XCTFail("Could not inspect the visible mark for \(title): \(error)", file: file, line: line)
            }
        }
    }
}

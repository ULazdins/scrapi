import XCTest
import SwiftSoup
@testable import Extractor

final class ParserTests_print: XCTestCase {
    func testValue_number() throws {
        let schema = Schema.value(
            .number
        )

        let result = try SchemaParser().print(schema)

        XCTAssertEqual(String(result), "Number")
    }
    
    func testSelectorAndValue() throws {
        let schema = Schema.selector(
            "div",
            .value(.number)
        )

        let result = try SchemaParser().print(schema)

        XCTAssertEqual(String(result), "\"div\" -> Number")
    }
    
    func testSelectorAndValue_nested() throws {
        let schema = Schema.selector(
            "div",
            .selector(
                "a",
                .value(.number)
            )
        )

        let result = try SchemaParser().print(schema)

        XCTAssertEqual(String(result), "\"div\" -> \"a\" -> Number")
    }
    
    func testObject() throws {
        let schema = Schema.object([
            "first1": .value(.number),
            "other": .selector("class", .value(.string))
        ])

        let result = try SchemaParser().print(schema)

        XCTAssertEqual(String(result), "{\"first1\":Number,\"other\":\"class\" -> String}")
    }
}

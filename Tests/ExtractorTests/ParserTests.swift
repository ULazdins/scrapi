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

final class ParserTests_parse: XCTestCase {
    func testSimpleAttributeSelector() throws {
        let string = """
        Attribute[href]
        """
        
        let result = try SchemaParser().parse(string)
        
        XCTAssertEqual(
            result,
            .value(.attribute("href"))
        )
    }
    
    func testComplexSelector() throws {
        let string = """
        ["#filter_frm table[align=center] tr" : {"url" : ":nth-child(1) a" -> Attribute[href]}]
        """
        
        let result = try SchemaParser().parse(string)
        
        XCTAssertEqual(
            result,
            .array(
                "#filter_frm table[align=center] tr",
                .object([
                    "url": .selector(
                        ":nth-child(1) a",
                        .value(.attribute("href"))
                    )
                ])
            )
        )
    }
    
    func testComplexSelector2() throws {
        let string = """
        "#filter_frm table[align=center]" -> [ "tr" : { "url" : ":nth-child(1) a" -> Attribute[href] } ]
        """
        
        let result = try SchemaParser().parse(string)
        
        XCTAssertEqual(
            result,
            .selector(
                "#filter_frm table[align=center]",
                .array(
                    "tr",
                    .object([
                        "url": .selector(
                            ":nth-child(1) a",
                            .value(.attribute("href"))
                        )
                    ])
                )
            )
        )
    }
}

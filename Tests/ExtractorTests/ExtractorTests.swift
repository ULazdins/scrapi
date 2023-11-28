import XCTest
import SwiftSoup
import AnyCodable
@testable import Extractor

extension Encodable {
    func toString() -> String {
        let e = AnyEncodable(self)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try! encoder.encode(e)
        return String(data: data, encoding: .utf8)!
    }
}

final class ExtractorTests: XCTestCase {
    func testTagBody() throws {
        let html = "<a>Hello</a>"
        let soup = try SwiftSoup.parse(html)
        
        let result = try extractor(from: soup, selector: .selector("a", .value(.string)))
        
        XCTAssertEqual(result.toString(), "\"Hello\"")
    }
    
    func testTagBodiesFails() throws {
        let html = "<a>Hello</a><a>It's me</a>"
        let soup = try SwiftSoup.parse(html)
        
        XCTAssertThrowsError(try extractor(from: soup, selector: .selector("a", .value(.string))))
    }
    
    func testObject() throws {
        let html = "<a id='first'>Hello</a><a id='second'>12</a>"
        let soup = try SwiftSoup.parse(html)
        
        let result = try extractor(
            from: soup,
            selector: .object([
                "firstField": .selector("#first", .value(.string)),
                "secondField": .selector("#second", .value(.number))
            ])
        )
        
        XCTAssertEqual(
            result.toString(),
            """
            {"firstField":"Hello","secondField":12}
            """
        )
    }
    
//    func testSelectorAndTag() throws {
//        let html = "<div><a>Hello</a></div><div id='take-me'><a>It's me</a></div>"
//        let soup = try SwiftSoup.parse(html)
//        
//        let result = try extractor(from: soup, selector: .selector("a"))
//        
//        XCTAssertEqual(result, "Hello")
//    }
    
//    func testTagBodies() throws {
//        let html = "<a>Hello</a><a>It's me</a>"
//        let soup = try SwiftSoup.parse(html)
//        
//        let result = try extractor(from: soup, selector: .array(.selector("a")))
//        
//        XCTAssertEqual(
//            result,
//            """
//            ["Hello", "It's me"]
//            """
//        )
//    }
    
    func testIdSelector() throws {
        let html = """
        <div>
            <a id="not-me">Not me</a>
            <a id="me">Hello</a>
        </div>
        """
        let soup = try SwiftSoup.parse(html)
        
        let result = try extractor(from: soup, selector: .selector("#me", .value(.string)))
        
        XCTAssertEqual(result.toString(), "\"Hello\"")
    }
    
//    func testList() throws {
//        let html = """
//        <li>
//            <ul>Elem1</ul>
//            <ul>Elem2</ul>
//            <ul>Elem3</ul>
//        </li>
//        """
//        let soup = try SwiftSoup.parse(html)
//        
//        let result = try extractor(from: soup, selector: "li -> [ul: string]")
//        
//        XCTAssertEqual(
//            result,
//            """
//            ["Elem1", "Elem2", "Elem3"]
//            """
//        )
//    }
}

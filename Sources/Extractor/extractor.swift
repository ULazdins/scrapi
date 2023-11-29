import Foundation
import AnyCodable
import SwiftSoup

struct Err: Error {
    let message: String
}

extension Value {
    func extract(from element: Element) throws -> any Codable {
        switch self {
        case .string:
            let text = try element.text()
            return text
        case .number:
            let text = try element.text()
            if let n = Double(text) {
                return n
            }
            throw Err(message: "Not a number")
        case .bool:
            let text = try element.text()
            if text == "true" {
                return true
            } else if text == "false" {
                return false
            }
            throw Err(message: "Not a boolean")
        case .attribute(let attributeName):
            return try element.attr(attributeName)
        }
    }
}

public func extractor(from element: Element, selector: Schema, canBeMany: Bool = false) throws -> Codable {
    switch selector {
    case .value(let valueType):
        return try valueType.extract(from: element)
    case .selector(let selector, let childSchema):
        let childElement = try element.select(selector)
        
        if childElement.count > 1 {
            throw Err(message: "too many elements match \(selector)")
        } else if childElement.isEmpty() {
            return "whoopsie"
//            throw Err(message: "no element matches \(selector)")
        }
        
        return try extractor(from: childElement[0], selector: childSchema)
    case .object(let keysAndSelectors):
        let withValues: [String: AnyCodable] = try keysAndSelectors
            .mapValues { schema in
                return AnyCodable(try extractor(from: element, selector: schema))
            }
        
        return withValues
    case .array(let itemSelector, let childSchema):
        let itemChildren = try element.select(itemSelector)
        
        return try itemChildren.map { child in
            AnyCodable(try extractor(from: child, selector: childSchema))
        }
    }
}

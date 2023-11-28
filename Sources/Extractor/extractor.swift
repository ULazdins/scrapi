import Foundation
import AnyCodable
import SwiftSoup

struct Err: Error {
    let message: String
}

extension Value {
    func extract(from element: Element) throws -> any Codable {
        let text = try element.text()
        
        switch self {
        case .string:
            return text
        case .number:
            if let n = Double(text) {
                return n
            }
            throw Err(message: "Not a number")
        case .bool:
            if text == "true" {
                return true
            } else if text == "false" {
                return false
            }
            throw Err(message: "Not a boolean")
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
            throw Err(message: "too many!")
        }
        
        return try extractor(from: childElement[0], selector: childSchema)
    case .object(let keysAndSelectors):
        let withValues: [String: AnyCodable] = try keysAndSelectors
            .mapValues { schema in
                return AnyCodable(try extractor(from: element, selector: schema))
            }
        
        return withValues
    }
}

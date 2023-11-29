import Vapor
import SwiftSoup
import Extractor
import AnyCodable

struct ParseRequest: Codable {
    let url: String
    let selector: Schema
}

final class ScraperController {
    func parseFromUrl(_ req: Request) async throws -> String {
        let params = try req.query.decode(ParseRequest.self)
        
        return try await handleParseRequest(params)
    }
    
    func parseFromUrlPost(_ req: Request) async throws -> String {
        let params = try req.content.decode(ParseRequest.self)
        
        return try await handleParseRequest(params)
    }
    
    private func handleParseRequest(_ params: ParseRequest) async throws -> String {
        var url = URL(string: params.url)!
        url = url.addHTTPSScheme()
        
        let (html, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        
        let doc: Document = try SwiftSoup.parse(String(data: html, encoding: .utf8)!)
        
        let response = try extractor(from: doc, selector: params.selector)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data =  try encoder.encode(AnyCodable(response))
        return String.init(data: data, encoding: .utf8)!
    }
}

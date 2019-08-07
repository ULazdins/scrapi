//
//  SsController.swift
//  App
//
//  Created by Uģis Lazdiņš on 03/08/2019.
//

import Vapor
import CoreFoundation
import SwiftSoup

struct OtherParameter: Codable {
    var url: String
    var listSelector: String
    var attributeSelectors: [String: String]?
}
extension OtherParameter: Content { }

final class SsController {
    func other(_ req: Request) throws -> Future<[[String: String]]> {
        return (try! req.content.decode(OtherParameter.self))
            .flatMap { (params) -> EventLoopFuture<[[String: String]]> in
                return self.getData(req, url: URL(string: params.url)!)
                    .map({ (html) -> ([[String: String]]) in
                        return self.transformHtml(
                            html,
                            listSelector: params.listSelector,
                            attributeSelectors: params.attributeSelectors ?? [:]
                        )
                    })
            }
    }
    
    private func transformHtml(_ html: String, listSelector: String, attributeSelectors: [String: String]) -> [[String: String]] {
        let doc: Document = try! SwiftSoup.parse(html)
        
        let res: Elements = try! doc.select(listSelector)
        
        return res.map({ (element) -> [String: String] in
            return self.parseListItem(element: element, attributeSelectors: attributeSelectors)
        })
    }
    
    private func parseListItem(element: Element, attributeSelectors: [String: String]) -> [String: String] {
        let aa = attributeSelectors.map({ key, value -> (String, String) in
            let p = value.split(separator: "|")
            let selector = String(p.first!)
            var valueReader: String? = p.count > 1 ? p[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) : nil
            if valueReader == "text" {
                valueReader = nil
            }
            
            let elem = try? element.select(selector)
            let value: String? = elem.flatMap({ (elem) -> String? in
                return try? valueReader.map(elem.attr) ?? elem.text()
            })
            return (key, (value ?? "[Error]"))
        })
        
        return Dictionary(uniqueKeysWithValues: aa)
    }
    
    private func getData(_ req: Request, url: URL) -> Future<String> {
        let promise = req.eventLoop.newPromise(String.self)
        let r = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: r) { (data, response, error) in
            if let error = error {
//                print("<--", error.localizedDescription)
                promise.fail(error: error)
                return
            }
            
//            print("<--", String(data: data!, encoding: .utf8)!)
            promise.succeed(result: String(data: data!, encoding: .utf8)!)
        }
        task.resume()
        
        return promise.futureResult
    }
}

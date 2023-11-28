import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {
    // Basic "It works" example
    app.get { req in
        return "It works!"
    }
    
    let scraperController = ScraperController()
    app.get("scrape", use: scraperController.parseFromUrl)
}

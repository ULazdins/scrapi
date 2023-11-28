import Foundation

extension URL {
    func addHTTPSScheme() -> URL {
        // Create a URLComponents object
        guard var urlComponents = URLComponents.init(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
            
        // Set the scheme to "https"
        urlComponents.scheme = "https"
            
            // Retrieve the updated URL
        return urlComponents.url!
    }
}

import Foundation

public extension URL {
    func resized(width: Int) -> URL {
        let urlString = "https://res.cloudinary.com/dlnmdbcom/image/fetch/w_\(width * 2)/\(self.absoluteString)"
        return URL(string: urlString) ?? self
    }
}

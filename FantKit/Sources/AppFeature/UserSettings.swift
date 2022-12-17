import APIClient
import Build
import ComposableArchitecture
import UIKit

public struct UserSettings: Codable, Equatable {
    public init(
    ) {
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
    }
}

public struct DeveloperSettings: Equatable {
    public var currentBaseUrl: BaseUrl
    
    public init(currentBaseUrl: BaseUrl = .production) {
        self.currentBaseUrl = currentBaseUrl
    }
    
    public enum BaseUrl: String, CaseIterable {
        case localhost = "http://localhost:9876"
        case localhostTunnel = "https://pointfreeco-localhost.ngrok.io"
        case production = "https://www.isowords.xyz"
        case staging = "https://isowords-staging.herokuapp.com"
        
        var description: String {
            switch self {
            case .localhost:
                return "Localhost"
            case .localhostTunnel:
                return "Localhost Tunnel"
            case .production:
                return "Production"
            case .staging:
                return "Staging"
            }
        }
        
        var url: URL { URL(string: self.rawValue)! }
    }
}

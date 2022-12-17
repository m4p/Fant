import Foundation
import KeychainAccess
import Logging
import Constants

public struct Defaults {
    @Storage(key: "additionalLocalTimeLines", defaultValue: []) public static var additionalLocalTimeLines: [String]
    @Storage(key: "host", defaultValue: URL(string: "https://mastodon.social")) public static var host: URL?
    @Storage(key: "email", defaultValue: "") public static var email: String
    @SecureStorage(key: "password", defaultValue: "", shouldSync: true) public static var password: String
    @SecureStorage(key: "token", defaultValue: nil, shouldSync: true) public static var token: String?

    public static var hasToken: Bool {
        return token != nil
    }
    
    public static var loginDataComplete: Bool {
        guard host != nil, !email.isEmpty, !password.isEmpty else { return false }
        return true
    }
}

@propertyWrapper
public struct Storage<Value: Codable> {
    private let key: String
    private let defaultValue: Value
    
    init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: Value {
        get {
            // Read value from UserDefaults
            if let data = UserDefaults.standard.object(forKey: key) as? Data,
               let value = try? JSONDecoder().decode(Value.self, from: data) {
                return value
            }
            return defaultValue
        }
        set {
            // Set value to UserDefaults
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
}

@propertyWrapper public struct SecureStorage<Value: Codable> {
    private let key: String
    private let defaultValue: Value
    private let syncing: Bool
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private let syncingKeychain = Keychain(service: Constants.accessGroup, accessGroup: Constants.accessGroup)
        .synchronizable(true)
        .accessibility(.always)
    
    private let localKeychain = Keychain(service: Constants.accessGroup, accessGroup: Constants.accessGroup)
        .synchronizable(false)
        .accessibility(.always)
    
    private var keychain: Keychain {
        guard syncing else { return localKeychain }
        return syncingKeychain
    }
    
    init(key: String, defaultValue: Value, shouldSync: Bool = false) {
        self.key = key
        self.defaultValue = defaultValue
        self.syncing = shouldSync
    }
    
    public var wrappedValue: Value {
        get {
            guard let data = try? keychain.getData(key),
                  let value = try? decoder.decode(Value.self, from: data) else { return defaultValue }
            return value
        }
        
        set {
            guard let data = try? encoder.encode(newValue) else {
                log.error("Cannot encode \(newValue) for keychain")
                return
            }
            do {
                try keychain.set(data, key: key)
            } catch {
                log.error("Cannot set \(newValue) for keychain", error)
            }
        }
    }
}

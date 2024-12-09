
import Foundation

struct State: Codable {
    var client: ClientState
    var account: AccountState
}

struct ClientState: Codable {
    var build: String
}

struct AccountState: Codable {
    var accounts: [Account]
}

struct Account: Codable {
    var accountId: String
    var state: State
    var key: Key
    var createdAt: Date
    var updatedAt: Date

    enum State: String, Codable {
        case active
    }
}

struct Key: Codable {
    var issuer: String
    var username: String
    var algorithm: Algorithm
    var digits: Int
    var period: Int

    enum Algorithm: String, Codable {
        case sha1, sha256, sha512
    }
}

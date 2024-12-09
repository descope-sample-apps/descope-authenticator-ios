
import Foundation

protocol Action {}

enum Actions {
    struct LoadState: Action {
        let state: State
    }

    struct AddAccount: Action {
        let accountId: String
        let key: Key
        let createdAt: Date
    }

    struct RemoveAccount: Action {
        let accountId: String
        let removedAt: Date
    }
}

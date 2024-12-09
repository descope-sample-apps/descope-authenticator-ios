
import UIKit

@MainActor
protocol AccountManagerDelegate: AnyObject {
    func accountManagerWillAddAccount(_ accountManager: AccountManager, accountId: String)
    func accountManagerDidAddAccount(_ accountManager: AccountManager, accountId: String)
}

@MainActor
protocol AccountManager: AnyObject {
    func addAccount(key: Key, secret: Data)
    func removeAccount(accountId: String)

    func addDelegate(_ delegate: AccountManagerDelegate)
    func removeDelegate(_ delegate: AccountManagerDelegate)
}

class AccountManagerClass: AccountManager {
    let model: Model
    let keychainManager: KeychainManager

    init(model: Model, keychainManager: KeychainManager) {
        self.model = model
        self.keychainManager = keychainManager
    }

    // Actions

    func addAccount(key: Key, secret: Data) {
        let accountId = Account.generateAccountId()
        try? keychainManager.saveSecret(secret, for: accountId)

        delegates.forEach { $0.accountManagerWillAddAccount(self, accountId: accountId) }

        model.dispatch(Actions.AddAccount(accountId: accountId, key: key, createdAt: .now))
        model.save()

        delegates.forEach { $0.accountManagerDidAddAccount(self, accountId: accountId) }
    }

    func removeAccount(accountId: String) {
        try? keychainManager.deleteSecret(for: accountId)

        model.dispatch(Actions.RemoveAccount(accountId: accountId, removedAt: .now))
        model.save()
    }

    // Delegates

    let delegates = WeakCollection<AccountManagerDelegate>()

    func addDelegate(_ delegate: AccountManagerDelegate) {
        delegates.add(delegate)
    }

    func removeDelegate(_ delegate: AccountManagerDelegate) {
        delegates.remove(delegate)
    }
}

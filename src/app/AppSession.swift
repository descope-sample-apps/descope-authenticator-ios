
import UIKit

@MainActor
class AppSession {
    let model: Model
    let keychainManager: KeychainManager
    let accountManager: AccountManager

    lazy var coordinator = AppCoordinator(model: model, keychainManager: keychainManager, accountManager: accountManager)

    init() {
        self.model = Model()
        self.keychainManager = KeychainManagerClass()
        self.accountManager = AccountManagerClass(model: model, keychainManager: keychainManager)
    }

    // Lifecycle

    func start() {
        model.load()
        coordinator.start()
    }

    func pause() {
        coordinator.pause()
    }

    func resume() {
        coordinator.resume()
    }

    // Links

    func didReceiveProvisioningURL(_ url: URL) {
        coordinator.handleProvisioningURL(url)
    }
}

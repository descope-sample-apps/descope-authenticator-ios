
import UIKit

@MainActor
class AppCoordinator: HomeCoordinatorDelegate, AddCoordinatorDelegate {
    private let model: Model
    private let keychainManager: KeychainManager
    private let accountManager: AccountManager

    private let window: UIWindow
    private let homeCoordinator: HomeCoordinator

    private var addCoordinator: AddCoordinator?

    init(model: Model, keychainManager: KeychainManager, accountManager: AccountManager) {
        self.model = model
        self.keychainManager = keychainManager
        self.accountManager = accountManager
        self.window = UIWindow()
        self.homeCoordinator = HomeCoordinator(model: model, keychainManager: keychainManager, accountManager: accountManager)

        homeCoordinator.delegate = self
    }

    var rootViewController: UIViewController {
        return homeCoordinator.rootViewController
    }

    // Lifecycle

    func start() {
        window.tintColor = .accent
        window.backgroundColor = .black
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
    }

    func pause() {
        // nothing
    }

    func resume() {
        // nothing
    }

    // Links

    func handleProvisioningURL(_ url: URL) {
        if addCoordinator != nil {
            rootViewController.dismiss(animated: false)
            addCoordinator = nil
        }

        do {
            let (key, secret) = try Key.parse(url: url)
            accountManager.addAccount(key: key, secret: secret)
        } catch .unsupported {
            Log.d("Captured unsupported key URL", url)
        } catch /* .malformed */ { // https://github.com/swiftlang/swift/issues/74555
            Log.d("Captured malformed key URL", url)
        }
    }

    // HomeCoordinatorDelegate

    func coordinatorDidPresentAddAccount(_ coordinator: HomeCoordinator) {
        addCoordinator = AddCoordinator(model: model, accountManager: accountManager)
        addCoordinator?.delegate = self

        rootViewController.present(addCoordinator!.rootViewController, animated: true)
    }

    // AddCoordinatorDelegate

    func coordinatorDidFinish(_ coordinator: AddCoordinator) {
        rootViewController.dismiss(animated: true)
        addCoordinator = nil
    }

    func coordinatorDidCancel(_ coordinator: AddCoordinator, dismissed: Bool) {
        if !dismissed {
            rootViewController.dismiss(animated: true)
        }
        addCoordinator = nil
    }
}

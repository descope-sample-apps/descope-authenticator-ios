
import UIKit

@MainActor
protocol HomeCoordinatorDelegate: AnyObject {
    func coordinatorDidPresentAddAccount(_ coordinator: HomeCoordinator)
}

@MainActor
class HomeCoordinator: HomeViewModelCoordinator {
    weak var delegate: HomeCoordinatorDelegate?

    private let model: Model
    private let keychainManager: KeychainManager
    
    private let navigationController = UINavigationController()

    init(model: Model, keychainManager: KeychainManager, accountManager: AccountManager) {
        self.model = model
        self.keychainManager = keychainManager

        let homeViewModel = HomeViewModelClass(model: model, keychainManager: keychainManager, accountManager: accountManager)
        homeViewModel.coordinator = self

        let homeViewController = HomeViewController(viewModel: homeViewModel)
        navigationController.viewControllers = [homeViewController]

        navigationController.navigationBar.prefersLargeTitles = true
    }

    var rootViewController: UIViewController {
        return navigationController
    }

    // HomeViewModelCoordinator

    func viewModelDidPresentAddAccount(_ viewModel: HomeViewModel) {
        delegate?.coordinatorDidPresentAddAccount(self)
    }
}

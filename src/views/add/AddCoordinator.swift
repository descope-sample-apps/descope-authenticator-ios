
import UIKit

@MainActor
protocol AddCoordinatorDelegate: AnyObject {
    func coordinatorDidFinish(_ coordinator: AddCoordinator)
    func coordinatorDidCancel(_ coordinator: AddCoordinator, dismissed: Bool)
}

@MainActor
class AddCoordinator: NSObject, AddViewModelCoordinator {
    weak var delegate: AddCoordinatorDelegate?

    private let model: Model
    private let accountManager: AccountManager
    
    private let navigationController = UINavigationController()

    init(model: Model, accountManager: AccountManager) {
        self.model = model
        self.accountManager = accountManager
        super.init()

        let addViewModel = AddViewModelClass(model: model, accountManager: accountManager)
        addViewModel.coordinator = self

        let addViewController = AddViewController(viewModel: addViewModel)
        navigationController.presentationController?.delegate = self
        navigationController.viewControllers = [addViewController]

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
    }

    var rootViewController: UIViewController {
        return navigationController
    }

    // AddViewModelCoordinator

    func viewModelDidFinish(_ viewModel: AddViewModel) {
        delegate?.coordinatorDidFinish(self)
    }

    func viewModelDidCancel(_ viewModel: AddViewModel) {
        delegate?.coordinatorDidCancel(self, dismissed: false)
    }
}

extension AddCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.coordinatorDidCancel(self, dismissed: true)
    }
}

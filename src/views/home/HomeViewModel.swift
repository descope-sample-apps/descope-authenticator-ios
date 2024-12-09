
import UIKit

struct HomeViewState: Equatable {
    var accounts: [Account] = []
    
    struct Account: Equatable {
        var id: String
        var title: String
        var subtitle: String
        var code: String?
    }
}

@MainActor
protocol HomeViewModelDelegate: AnyObject {
    func viewModelDidUpdateState(_ viewModel: HomeViewModel)
    func viewModelWillAnimateAddAccount(_ viewModel: HomeViewModel)
    func viewModelDidAnimateAddAccount(_ viewModel: HomeViewModel)
}

@MainActor
protocol HomeViewModelCoordinator: AnyObject {
    func viewModelDidPresentAddAccount(_ viewModel: HomeViewModel)
}

@MainActor
protocol HomeViewModel: AnyObject {
    var delegate: HomeViewModelDelegate? { get set }
    var coordinator: HomeViewModelCoordinator? { get set }
    var state: HomeViewState { get }
    func handleAppeared()
    func handleDisappeared()
    func handleAddPressed()
    func handleAccountSelected(index: Int)
    func handleAccountRemoved(index: Int)
}

class HomeViewModelClass: HomeViewModel, ModelDelegate, AccountManagerDelegate {
    weak var delegate: HomeViewModelDelegate?
    weak var coordinator: HomeViewModelCoordinator?

    let model: Model
    let keychainManager: KeychainManager
    let accountManager: AccountManager

    init(model: Model, keychainManager: KeychainManager, accountManager: AccountManager) {
        self.model = model
        self.keychainManager = keychainManager
        self.accountManager = accountManager

        model.addDelegate(self)
        accountManager.addDelegate(self)

        updateState()
    }
    
    // State
    
    var state = HomeViewState()

    func updateState() {
        var state = HomeViewState()
        
        state.accounts = model.state.account.accounts.filter { account in
            return account.state == .active
        }.sorted { a, b in
            return a.createdAt > b.createdAt
        }.map { account in
            return HomeViewState.Account(id: account.accountId, title: account.key.issuer, subtitle: account.key.username, code: generateCode(for: account))
        }

        if self.state != state {
            self.state = state
            delegate?.viewModelDidUpdateState(self)
        }
    }

    // ModelDelegate

    func modelDidUpdate(_ model: Model) {
        updateState()
    }

    // AccountManagerDelegate

    func accountManagerWillAddAccount(_ accountManager: AccountManager, accountId: String) {
        delegate?.viewModelWillAnimateAddAccount(self)
    }

    func accountManagerDidAddAccount(_ accountManager: AccountManager, accountId: String) {
        delegate?.viewModelDidAnimateAddAccount(self)
    }

    // Actions
    
    func handleAppeared() {
        updateState()
        updateTimer()
    }
    
    func handleDisappeared() {
        resetTimer()
    }
    
    func handleAddPressed() {
        coordinator?.viewModelDidPresentAddAccount(self)
    }
    
    func handleAccountSelected(index: Int) {
        let code = state.accounts[index].code
        UIPasteboard.general.string = code
    }
    
    func handleAccountRemoved(index: Int) {
        let accountId = state.accounts[index].id
        accountManager.removeAccount(accountId: accountId)
    }

    // Code

    func generateCode(for account: Account) -> String? {
        guard let secret = try? keychainManager.loadSecret(for: account.accountId) else { return nil }
        let code = account.key.generateCode(with: secret)
        return code
    }

    // Timer

    var timer: Timer?

    func updateTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerDidTick), userInfo: nil, repeats: true)
    }

    func resetTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc func timerDidTick() {
        updateState()
    }
}

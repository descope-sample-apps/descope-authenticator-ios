
import UIKit

class HomeViewController: UIViewController, HomeViewModelDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var emptyView: UIView!

    let viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String(localized: "home.title")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didPressAddAccount))
        tableView.register(UINib(nibName: AccountCell.identifier, bundle: nil), forCellReuseIdentifier: AccountCell.identifier)
        updateViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Log.i("Home appeared")
        viewModel.handleAppeared()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Log.i("Home disappeared")
        viewModel.handleDisappeared()
    }

    // Views

    var isAnimating = false

    func updateViews() {
        guard isViewLoaded, !isAnimating else { return }
        emptyView.isHidden = !viewModel.state.accounts.isEmpty
        tableView.reloadData()
    }

    // Actions

    @IBAction private func didPressAddAccount() {
        Log.i("Add Account pressed")
        viewModel.handleAddPressed()
    }

    // Animations

    func willAddAccount() {
        emptyView.isHidden = true
        isAnimating = true
    }

    func didAddAccount() {
        tableView.performBatchUpdates {
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        } completion: { [self] completed in
            isAnimating = false
            updateViews()
        }
    }

    func willRemoveAccount(index: Int) {
        let alert = UIAlertController(title: viewModel.state.accounts[index].title, message: String(localized: "home.remove.message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "button.cancel"), style: .default))
        alert.addAction(UIAlertAction(title: String(localized: "button.remove"), style: .destructive, handler: { [weak self] action in
            self?.didRemoveAccount(index: index)
        }))
        present(alert, animated: true)
    }

    func didRemoveAccount(index: Int) {
        isAnimating = true
        viewModel.handleAccountRemoved(index: index)
        tableView.performBatchUpdates {
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
        } completion: { [self] completed in
            isAnimating = false
            UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve) { [self] in
                updateViews()
            }
        }
    }

    // HomeViewModelDelegate

    func viewModelDidUpdateState(_ viewModel: HomeViewModel) {
        updateViews()
    }

    func viewModelWillAnimateAddAccount(_ viewModel: HomeViewModel) {
        willAddAccount()
    }

    func viewModelDidAnimateAddAccount(_ viewModel: HomeViewModel) {
        // short delay to let any dismissed view or app transitions complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            didAddAccount()
        }
    }

    // UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Log.i("Selected account", indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.handleAccountSelected(index: indexPath.row)
    }

    // UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.accounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell.identifier, for: indexPath) as! AccountCell
        cell.account = viewModel.state.accounts[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: String(localized: "button.remove"), handler: { [weak self] action, sourceView, completionHandler in
            self?.willRemoveAccount(index: indexPath.row)
            completionHandler(true)
        })
        return UISwipeActionsConfiguration(actions: [action])
    }
}

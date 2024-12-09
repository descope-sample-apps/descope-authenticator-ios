
import UIKit

@MainActor
protocol ModelDelegate: AnyObject {
    func modelDidUpdate(_ model: Model)
}

@MainActor
class Model {
    private(set) var state: State = .initial

    func dispatch(_ action: Action) {
        Log.d("Dispatching action", action)
        state = state.reduce(action: action)
        delegates.forEach { $0.modelDidUpdate(self) }
    }

    // Storage

    private let storageManager = StorageManager()

    func load() {
        if let state = storageManager.loadState() {
            dispatch(Actions.LoadState(state: state))
        }
    }

    func save() {
        storageManager.saveStateAsync(state)
    }

    // Delegates

    private let delegates = WeakCollection<ModelDelegate>()

    func addDelegate(_ delegate: ModelDelegate) {
        delegates.add(delegate)
    }

    func removeDelegate(_ delegate: ModelDelegate) {
        delegates.remove(delegate)
    }
}

extension Account {
    static func generateAccountId() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}


import Foundation

extension State {
    static let initial = State(client: .initial, account: .initial)
    
    func reduce(action: Action) -> State {
        var state = self
        state.client = client.reduce(action: action)
        state.account = account.reduce(action: action)
        return state
    }
}

extension ClientState {
    static let initial = ClientState(build: AppBuild)

    func reduce(action: Action) -> ClientState {
        var state = self

        switch action {
        case let action as Actions.LoadState:
            state = action.state.client
            state.build = AppBuild

        default:
            break
        }

        return state
    }
}

extension AccountState {
    static let initial = AccountState(accounts: [])

    func reduce(action: Action) -> AccountState {
        var state = self

        switch action {
        case let action as Actions.LoadState:
            state = action.state.account

        case let action as Actions.AddAccount:
            let account = Account(accountId: action.accountId, state: .active, key: action.key, createdAt: action.createdAt, updatedAt: action.createdAt)
            state.accounts.append(account)

        case let action as Actions.RemoveAccount:
            state.accounts.removeAll { $0.accountId == action.accountId }

        default:
            break
        }

        return state
    }
}

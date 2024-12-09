
import Foundation

enum KeychainManagerError: String, Error {
    case keychainUnavailable
    case missingData
    case unexpectedFailure
}

protocol KeychainManager: AnyObject {
    func saveSecret(_ secret: Data, for accountId: String) throws(KeychainManagerError)
    func loadSecret(for accountId: String) throws(KeychainManagerError) -> Data
    func deleteSecret(for accountId: String) throws(KeychainManagerError)
}

class KeychainManagerClass: KeychainManager {
    func saveSecret(_ secret: Data, for accountId: String) throws(KeychainManagerError) {
        try save(tag: "secret", accountId: accountId, data: secret)
    }

    func loadSecret(for accountId: String) throws(KeychainManagerError) -> Data {
        return try load(tag: "secret", accountId: accountId)
    }

    func deleteSecret(for accountId: String) throws(KeychainManagerError) {
        try delete(tag: "secret", accountId: accountId)
    }

    private func load(tag: String, accountId: String) throws(KeychainManagerError) -> Data {
        var query = createQuery(tag: tag, accountId: accountId)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return data
        }

        switch status {
        case errSecInteractionNotAllowed:
            Log.i("Cannot load keychain data while device is locked")
            throw .keychainUnavailable
        case errSecItemNotFound:
            Log.e("Failed to find required keychain data")
            throw .missingData
        default:
            Log.e("Unexpected failure loading keychain data", status)
            throw .unexpectedFailure
        }
    }

    private func save(tag: String, accountId: String, data: Data) throws(KeychainManagerError) {
        var query = createQuery(tag: tag, accountId: accountId)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            Log.e("Unexpected failure saving keychain data", status)
            throw .unexpectedFailure
        }
        Log.i("Keychain data saved for account \(accountId)")
    }

    private func delete(tag: String, accountId: String) throws(KeychainManagerError) {
        let query = createQuery(tag: tag, accountId: accountId)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            Log.e("Unexpected failure deleting keychain data", status)
            throw .unexpectedFailure
        }
        Log.i("Keychain data deleted for account \(accountId)")
    }

    private func createQuery(tag: String, accountId: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountId,
            kSecAttrService as String: tag,
            kSecAttrSynchronizable as String: true,
        ]
    }
}

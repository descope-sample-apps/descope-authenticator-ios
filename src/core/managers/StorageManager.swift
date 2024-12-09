
import UIKit

private let stateFile = "state.json"

final class StorageManager: Sendable {
    @MainActor
    func loadState() -> State? {
        do {
            let startedAt = CACurrentMediaTime()
            guard let state = try readStateFile() else { return nil }
            let finishedAt = CACurrentMediaTime()
            let millis = Int(1000 * (finishedAt - startedAt))
            Log.i("State from build \(state.client.build) loaded in \(millis)ms")
            return state
        } catch {
            Log.e("Failed to load state", error)
        }
        return nil
    }
    
    @MainActor
    func saveStateAsync(_ state: State) {
        UIApplication.shared.performBackgroundTask { completion in
            storageQueue.async { [self] in
                saveState(state)
                completion()
            }
        }
    }

    private func saveState(_ state: State) {
        do {
            let startedAt = CACurrentMediaTime()
            try writeStateFile(state)
            let finishedAt = CACurrentMediaTime()
            let millis = Int(1000 * (finishedAt - startedAt))
            Log.i("State saved in \(millis)ms")
        } catch {
            Log.e("Failed to save state", error)
        }
    }

    // Files

    private func readStateFile() throws -> State? {
        guard FileManager.default.fileExists(atPath: stateFileURL.path) else { return nil }
        let data = try Data(contentsOf: stateFileURL)
        return try JSONDecoder().decode(State.self, from: data)
    }
    
    private func writeStateFile(_ state: State) throws {
        let data = try JSONEncoder().encode(state)
        let kilobytes = Int(ceil(Double(data.count) / 1024))
        Log.d("Saving state (\(kilobytes)KB)")
        try data.write(to: stateFileURL, options: [.atomic])
    }

    // Paths

    private var stateFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(stateFile)
    }

    // Queue

    private let storageQueue = createStorageQueue()

    private static func createStorageQueue() -> DispatchQueue {
        return DispatchQueue(label: "\(AppIdentifier).StorageService", qos: .userInitiated)
    }
}

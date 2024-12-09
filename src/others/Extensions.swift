
import UIKit

extension UIApplication {
    typealias BackgroundTaskCompletionHandler = @Sendable () -> Void

    func performBackgroundTask(withName name: String = #function, task: (@escaping BackgroundTaskCompletionHandler) -> Void) {
        var identifier: UIBackgroundTaskIdentifier = .invalid

        let expirationHandler = { @MainActor [self] in
            guard identifier != .invalid else { return }
            endBackgroundTask(identifier)
            identifier = .invalid
        }

        identifier = beginBackgroundTask(withName: name) {
            expirationHandler()
        }

        let completionHandler: BackgroundTaskCompletionHandler = {
            DispatchQueue.main.async {
                expirationHandler()
            }
        }

        task(completionHandler)
    }
}


import UIKit

struct AddViewState {
    var key: Key?
}

@MainActor
protocol AddViewModelDelegate: AnyObject {
    func viewModelDidUpdateState(_ viewModel: AddViewModel)
    func viewModelDidStartCamera(_ viewModel: AddViewModel)
    func viewModelDidScanKey(_ viewModel: AddViewModel, key: Key)
}

@MainActor
protocol AddViewModelCoordinator: AnyObject {
    func viewModelDidFinish(_ viewModel: AddViewModel)
    func viewModelDidCancel(_ viewModel: AddViewModel)
}

@MainActor
protocol AddViewModel: AnyObject {
    var delegate: AddViewModelDelegate? { get set }
    var coordinator: AddViewModelCoordinator? { get set }
    var state: AddViewState { get }
    var previewLayer: CALayer { get }
    func handleAppeared()
    func handleDisappeared()
    func handleCancelPressed()
    func handleSavePressed()
}

class AddViewModelClass: AddViewModel, CameraManagerDelegate {
    weak var delegate: AddViewModelDelegate?
    weak var coordinator: AddViewModelCoordinator?

    let accountManager: AccountManager
    let cameraManager: CameraManager

    init(model: Model, accountManager: AccountManager) {
        self.accountManager = accountManager
        #if targetEnvironment(simulator)
        self.cameraManager = CameraManagerMock()
        #else
        self.cameraManager = CameraManagerClass()
        #endif

        cameraManager.delegate = self
    }

    var previewLayer: CALayer {
        return cameraManager.previewLayer
    }

    // State
    
    var state = AddViewState()

    func updateState() {
        var state = AddViewState()

        state.key = scanned?.key

        self.state = state
        delegate?.viewModelDidUpdateState(self)
    }

    // Actions
    
    func handleAppeared() {
        Log.i("Starting camera")
        do {
            try cameraManager.start()
        } catch {
            Log.e("Failed to start camera manager", error)
        }
    }

    func handleDisappeared() {
        cameraManager.stop()
    }

    func handleCancelPressed() {
        coordinator?.viewModelDidCancel(self)
    }

    func handleSavePressed() {
        guard let scanned else { preconditionFailure("Expected view model to have a key when saving") }
        accountManager.addAccount(key: scanned.key, secret: scanned.secret)
        coordinator?.viewModelDidFinish(self)
    }

    // Scanning

    var scanned: (url: URL, key: Key, secret: Data)?

    func didScan(url: URL, key: Key, secret: Data) {
        guard scanned == nil else { return }

        Log.i("Scanned invitation URL", url, key)
        scanned = (url, key, secret)
        updateState()

        delegate?.viewModelDidScanKey(self, key: key)
    }

    // CameraManagerDelegate

    var started: Date = .distantPast

    func cameraManagerDidStart(_ cameraManager: CameraManager) {
        Log.d("Scanning for invitation QR code")
        started = .now
        delegate?.viewModelDidStartCamera(self)
    }

    func cameraManagerDidCapture(_ cameraManager: CameraManager, value: String) {
        guard Date.now.timeIntervalSince(started) > 1 else { return } // short delay to let screen fully appear
        guard let url = URL(string: value) else { return Log.d("Captured invalid value from camera", value) }
        guard url.scheme == Key.scheme else { return Log.d("Captured generic URL", value) }
        do {
            let (key, secret) = try Key.parse(url: url)
            didScan(url: url, key: key, secret: secret)
        } catch .unsupported {
            Log.d("Captured unsupported key URL", url)
        } catch /* .malformed */ { // https://github.com/swiftlang/swift/issues/74555
            Log.d("Captured malformed key URL", url)
        }
    }
}


import UIKit
import AudioToolbox

class AddViewController: UIViewController, AddViewModelDelegate {
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var previewView: AddViewPreviewView!
    @IBOutlet var keyView: UIView!
    @IBOutlet var scannedLabel: UILabel!
    @IBOutlet var issuerLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!

    let viewModel: AddViewModel

    init(viewModel: AddViewModel) {
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

        UINotificationFeedbackGenerator().prepare()

        navigationItem.title = String(localized: "add.title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "button.cancel"), primaryAction: UIAction { [weak self] _ in self?.didPressCancel() })

        previewView.previewLayer = viewModel.previewLayer
        saveButton.setTitle(String(localized: "button.save"), for: .normal)
        scannedLabel.text = String(localized: "add.scanned")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Log.i("Add appeared")
        viewModel.handleAppeared()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Log.i("Add disappeared")
        viewModel.handleDisappeared()
    }

    // Views

    func updateViews() {
        guard isViewLoaded else { return }

        issuerLabel.text = viewModel.state.key?.issuer ?? ""
        usernameLabel.text = viewModel.state.key?.username ?? ""
    }

    // Actions

    func didPressCancel() {
        Log.i("Cancel pressed")
        viewModel.handleCancelPressed()
    }

    @IBAction func didPressSave() {
        Log.i("Save pressed")
        viewModel.handleSavePressed()
    }

    // HomeViewModelDelegate

    func viewModelDidUpdateState(_ viewModel: AddViewModel) {
        updateViews()
    }

    func viewModelDidStartCamera(_ viewModel: AddViewModel) {
        UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut) { [self] in
            previewView.alpha = 1
        }
    }

    func viewModelDidScanKey(_ viewModel: AddViewModel, key: Key) {
        playShutterSound()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIView.animate(withDuration: 0.3) { [self] in
            keyView.alpha = 1
        }
    }
}

class AddViewPreviewView: UIView {
    var previewLayer: CALayer? {
        willSet {
            previewLayer?.removeFromSuperlayer()
        }
        didSet {
            guard let previewLayer else { return }
            previewLayer.frame = layer.bounds
            layer.addSublayer(previewLayer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = layer.bounds
    }
}

private func playShutterSound() {
    AudioServicesPlayAlertSound(1108) // https://theapplewiki.com/wiki/Dev:AudioServices
}

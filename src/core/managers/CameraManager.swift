
@preconcurrency import AVFoundation

enum CameraManagerError: String, Error {
    case cameraNotFound
    case cantOpenCamera
    case inputNotAvailable
    case outputNotAvailable
}

@MainActor
protocol CameraManagerDelegate: AnyObject {
    func cameraManagerDidStart(_ cameraManager: CameraManager)
    func cameraManagerDidCapture(_ cameraManager: CameraManager, value: String)
}

@MainActor
protocol CameraManager: AnyObject {
    var delegate: CameraManagerDelegate? { get set }
    var previewLayer: CALayer { get }
    var hasPermission: Bool { get }
    func start() throws(CameraManagerError)
    func stop()
}

class CameraManagerClass: NSObject, CameraManager, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: CameraManagerDelegate?
    
    private let layer: AVCaptureVideoPreviewLayer
    private var session: AVCaptureSession?

    override init() {
        layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
    }
    
    deinit {
        session?.stopRunning()
    }
                
    // Lifecycle
    
    func start() throws(CameraManagerError) {
        guard session == nil else { return Log.w("CameraManager already started") }

        session = try createSession()
        layer.session = session

        cameraQueue.async { [session] in
            session?.startRunning()
            DispatchQueue.main.async { [self] in
                delegate?.cameraManagerDidStart(self)
            }
        }
    }
    
    func stop() {
        guard session != nil else { return Log.w("CameraManager wasn't started") }

        cameraQueue.sync {
            session?.stopRunning()
            session = nil
        }
        
        layer.removeFromSuperlayer()
        layer.session = nil
    }

    var previewLayer: CALayer {
        return layer
    }

    var hasPermission: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    // Setup
        
    private func createSession() throws(CameraManagerError) -> AVCaptureSession {
        guard let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { throw CameraManagerError.cameraNotFound }
        let session = AVCaptureSession()
        try addInput(to: session, with: device)
        try addMetadataOutput(to: session)
        return session
    }
    
    private func addInput(to session: AVCaptureSession, with device: AVCaptureDevice) throws(CameraManagerError) {
        guard let input = try? AVCaptureDeviceInput(device: device) else { throw CameraManagerError.cantOpenCamera }
        guard session.canAddInput(input) else { throw CameraManagerError.inputNotAvailable }
        session.addInput(input)
    }

    private func addMetadataOutput(to session: AVCaptureSession) throws(CameraManagerError) {
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { throw CameraManagerError.outputNotAvailable}
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: cameraQueue)
        output.metadataObjectTypes = [ .qr ]
    }

    // AVCaptureMetadataOutputObjectsDelegate

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let values = metadataObjects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }.compactMap { $0.stringValue }
        for value in values {
            DispatchQueue.main.async { [self] in
                delegate?.cameraManagerDidCapture(self, value: value)
            }
        }
    }

    // Queue

    private let cameraQueue = createCameraQueue()

    private static func createCameraQueue() -> DispatchQueue {
        return DispatchQueue(label: "\(AppIdentifier).CameraManager", qos: .userInteractive)
    }
}

#if targetEnvironment(simulator)

class CameraManagerMock: CameraManager {
    weak var delegate: CameraManagerDelegate?

    var previewLayer = CALayer()

    var hasPermission = true

    var timer: Timer?

    func start() throws(CameraManagerError) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.previewLayer.backgroundColor = CGColor(gray: CGFloat.random(in: 0.2...0.3), alpha: 1)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            guard timer != nil else { return }
            delegate?.cameraManagerDidStart(self)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [self] in
            guard timer != nil else { return }
            let value = createMockInvitation()
            delegate?.cameraManagerDidCapture(self, value: value)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func createMockInvitation() -> String {
        let issuer = "Acme%20Corp%20\(Int.random(in: 10...99))"
        let username = "user%2B\(Int.random(in: 10...99))%40acmecorp.com"
        let key = String(repeating: "A", count: 16).map { _ in String("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".randomElement()!) }.joined()
        return "otpauth://totp/\(issuer):\(username)?secret=\(key)&issuer=\(issuer)"
    }
}

#endif

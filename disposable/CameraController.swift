import Foundation
import AVFoundation
import Photos
import UIKit
import Combine

@MainActor
final class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()

    @Published var errorMessage: String?

    // Flash toggle (default off to behave predictably)
    @Published var flashEnabled: Bool = false

    // Persistent countdown
    @Published var remainingShots: Int {
        didSet {
            UserDefaults.standard.set(remainingShots, forKey: Self.remainingShotsKey)
        }
    }

    // Persistent session name
    @Published var sessionName: String {
        didSet {
            UserDefaults.standard.set(sessionName, forKey: Self.sessionNameKey)
        }
    }

    private static let remainingShotsKey = "remainingShots"
    private static let sessionNameKey = "sessionName"
    private static let maxShots = 24

    override init() {
        let storedCount = UserDefaults.standard.object(forKey: Self.remainingShotsKey) as? Int
        let storedName = UserDefaults.standard.string(forKey: Self.sessionNameKey)
        self.remainingShots = storedCount ?? Self.maxShots
        self.sessionName = (storedName?.isEmpty == false) ? storedName! : Strings.Session.untitled
        super.init()
        // Normalize any invalid stored values
        if remainingShots <= 0 || remainingShots > Self.maxShots {
            remainingShots = Self.maxShots
        }
        if sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sessionName = Strings.Session.untitled
        }
    }

    func start() async {
        let authorized = await requestPermissions()
        guard authorized else {
            errorMessage = Strings.Alert.permissionsRequired
            return
        }

        do {
            try await configureSession()
            session.startRunning()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func capturePhoto() {
        // If we've hit zero, reset before capturing to maintain the disposable-like behavior
        if remainingShots == 0 {
            remainingShots = Self.maxShots
            // Prompt user to name the new session
            promptForSessionName()
        }

        let settings = AVCapturePhotoSettings()
        // Apply flash mode from toggle
        if photoOutput.supportedFlashModes.contains(.on), photoOutput.supportedFlashModes.contains(.off) {
            settings.flashMode = flashEnabled ? .on : .off
        } else {
            // Fallback if flash not supported; avoid crashing
            settings.flashMode = .off
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func requestPermissions() async -> Bool {
        let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        let photosGranted: Bool = await withCheckedContinuation { cont in
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    cont.resume(returning: status == .authorized || status == .limited)
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    cont.resume(returning: status == .authorized)
                }
            }
        }
        return cameraGranted && photosGranted
    }

    private func configureSession() async throws {
        try await withCheckedThrowingContinuation { cont in
            sessionQueue.async {
                do {
                    self.session.beginConfiguration()
                    self.session.sessionPreset = .photo

                    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                        throw NSError(domain: "Camera", code: 1, userInfo: [NSLocalizedDescriptionKey: Strings.Alert.noBackCamera])
                    }
                    let input = try AVCaptureDeviceInput(device: device)
                    if self.session.canAddInput(input) { self.session.addInput(input) }

                    if self.session.canAddOutput(self.photoOutput) {
                        self.session.addOutput(self.photoOutput)
                        self.photoOutput.isHighResolutionCaptureEnabled = true
                    }

                    self.session.commitConfiguration()
                    cont.resume()
                } catch {
                    self.session.commitConfiguration()
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func saveToPhotos(_ imageData: Data) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: imageData, options: nil)
        }) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "\(Strings.Alert.noBackCamera) \(error.localizedDescription)"
                    // Optional: error haptic
                    let notifier = UINotificationFeedbackGenerator()
                    notifier.prepare()
                    notifier.notificationOccurred(.error)
                    return
                }
                if success {
                    // Success haptic
                    let notifier = UINotificationFeedbackGenerator()
                    notifier.prepare()
                    notifier.notificationOccurred(.success)

                    // Decrement only on successful save
                    if self.remainingShots > 0 {
                        self.remainingShots -= 1
                    }
                    // Auto-reset when reaching zero so the next shot starts a fresh roll
                    if self.remainingShots == 0 {
                        // Reset the counter and prompt for a new session name
                        self.remainingShots = Self.maxShots
                        self.promptForSessionName()
                    }
                }
            }
        }
    }

    // MARK: - Watermarking

    private func watermarkText(for displayCount: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "dd-MM-yyyy"
        let datePart = formatter.string(from: Date())
        let name = sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Strings.Session.untitled : sessionName
        return "\(name) \(datePart) \(displayCount) of \(Self.maxShots)"
    }

    private func addWatermark(to image: UIImage, text: String) -> UIImage {
        // Choose a font size relative to image width for scalability
        let baseFontSize = max(24, image.size.width * 0.03)
        let font = UIFont.monospacedSystemFont(ofSize: baseFontSize, weight: .semibold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.orange,
            .paragraphStyle: paragraph
        ]

        let scale = image.scale
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = scale
        rendererFormat.opaque = true
        rendererFormat.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: image.size, format: rendererFormat)

        let padded: CGFloat = max(12, image.size.width * 0.02)
        let shadowOffset = CGSize(width: 0, height: max(1, image.size.height * 0.002))
        let shadowBlur: CGFloat = max(2, image.size.width * 0.005)

        let result = renderer.image { ctx in
            // Draw base image
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Shadow for legibility
//            ctx.cgContext.setShadow(offset: shadowOffset, blur: shadowBlur, color: UIColor.black.withAlphaComponent(0.6).cgColor)

            // Measure text
            let textSize = (text as NSString).size(withAttributes: attributes)

            // Bottom-right placement with padding
            let textOrigin = CGPoint(
                x: image.size.width - textSize.width - padded,
                y: image.size.height - textSize.height - padded
            )
            let textRect = CGRect(origin: textOrigin, size: textSize)
            
            // Apply blend mode + opacity just for the text
            let context = ctx.cgContext
            context.saveGState()
            context.setBlendMode(.hardLight)
            context.setAlpha(0.9)

            // Draw text
            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }

        return result
    }

    // MARK: - Session naming prompt

    private func promptForSessionName() {
        let alert = UIAlertController(title: Strings.Session.new, message: Strings.Session.namePrompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = Strings.Session.namePrompt
            textField.text = ""
            textField.returnKeyType = .done
        }

        let saveAction = UIAlertAction(title: Strings.Button.save, style: .default) { [weak self] _ in
            guard let self else { return }
            let entered = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.sessionName = entered.isEmpty ? Strings.Session.untitled : entered
        }
        let cancelAction = UIAlertAction(title: Strings.Button.cancel, style: .cancel) { [weak self] _ in
            self?.sessionName = Strings.Session.untitled
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)

        // Present from the topmost view controller
        if let presenter = self.topMostViewController() {
            presenter.present(alert, animated: true, completion: nil)
        } else {
            // Fallback if we cannot find a presenter
            self.sessionName = Strings.Session.untitled
        }
    }

    private func topMostViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topMostViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return base
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        if let error = error {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            return
        }
        guard let data = photo.fileDataRepresentation() else { return }

        // Watermark work off the main actor to avoid blocking UI
        Task.detached { [data] in
            // Capture the display value before any decrement (current state "X of 24")
            let displayCount = await MainActor.run { self.remainingShots }

            guard let original = UIImage(data: data) else {
                await MainActor.run { self.saveToPhotos(data) } // Fallback: save original
                return
            }

            let text = await MainActor.run { self.watermarkText(for: displayCount) }
            let watermarked = await MainActor.run { self.addWatermark(to: original, text: text) }

            // Encode as JPEG with reasonable quality
            let finalData = watermarked.jpegData(compressionQuality: 0.9) ?? data

            await MainActor.run {
                self.saveToPhotos(finalData)
            }
        }
    }
}

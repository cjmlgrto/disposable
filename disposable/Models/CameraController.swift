import Foundation
import AVFoundation
import Photos
import UIKit
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins

@MainActor
final class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private let filmFilter = PhotoFilter()

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
            // When session name changes, create or find the corresponding album
            createSessionAlbumIfNeeded { _ in }
        }
    }

    @Published var isPresentingSessionNamePrompt: Bool = false
    @Published var pendingSessionName: String = ""

    private static let remainingShotsKey = "remainingShots"
    private static let sessionNameKey = "sessionName"
    private static let albumIdentifierKey = "sessionAlbumIdentifier" // Persist album identifier
    private static let maxShots = 24

    // Store current session album identifier to save photos into
    private(set) var currentAlbumIdentifier: String? {
        didSet {
            // Persist the current album identifier for the session name
            if let id = currentAlbumIdentifier {
                UserDefaults.standard.set(id, forKey: Self.albumIdentifierKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.albumIdentifierKey)
            }
        }
    }

    override init() {
        let storedCount = UserDefaults.standard.object(forKey: Self.remainingShotsKey) as? Int
        let storedName = UserDefaults.standard.string(forKey: Self.sessionNameKey)
        self.remainingShots = storedCount ?? Self.maxShots
        self.sessionName = (storedName?.isEmpty == false) ? storedName! : Strings.Session.untitled
        self.currentAlbumIdentifier = nil
        super.init()
        // Normalize any invalid stored values
        if remainingShots <= 0 || remainingShots > Self.maxShots {
            remainingShots = Self.maxShots
        }
        if sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sessionName = Strings.Session.untitled
        }
        // Attempt to restore persisted album identifier for current session
        if let albumId = UserDefaults.standard.string(forKey: Self.albumIdentifierKey) {
            self.currentAlbumIdentifier = albumId
        }
        // Create or find album for initial session name
        createSessionAlbumIfNeeded { _ in }
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
            // Create asset for the photo
            let assetRequest = PHAssetCreationRequest.forAsset()
            assetRequest.addResource(with: .photo, data: imageData, options: nil)

            // If a current album exists, add the photo asset to that album
            if let albumId = self.currentAlbumIdentifier,
               let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil).firstObject {
                let addAssetRequest = PHAssetCollectionChangeRequest(for: collection)
                if let placeholder = assetRequest.placeholderForCreatedAsset {
                    addAssetRequest?.addAssets([placeholder] as NSArray)
                }
            }
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

    func promptForSessionName() {
        isPresentingSessionNamePrompt = true
        pendingSessionName = ""
    }

    /// Call when the user confirms the name in the overlay
    func confirmSessionNamePrompt() {
        let trimmed = pendingSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newName = trimmed.isEmpty ? Strings.Session.untitled : trimmed
        sessionName = newName
        isPresentingSessionNamePrompt = false
        createSessionAlbumIfNeeded { _ in }
    }

    /// Call when the user cancels
    func cancelSessionNamePrompt() {
        sessionName = Strings.Session.untitled
        isPresentingSessionNamePrompt = false
        createSessionAlbumIfNeeded { _ in }
    }

    /// Creates a photo album for the current session if it does not exist,
    /// and sets `currentAlbumIdentifier` to its local identifier.
    private func createSessionAlbumIfNeeded(completion: @escaping (String?) -> Void) {
        let albumName = "Disposable: \(sessionName)"
        // Check if album already exists
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        if let existing = (0..<fetch.count).map({ fetch.object(at: $0) }).first(where: { $0.localizedTitle == albumName }) {
            self.currentAlbumIdentifier = existing.localIdentifier
            completion(existing.localIdentifier)
            return
        }
        // Create new album
        var albumPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let create = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            albumPlaceholder = create.placeholderForCreatedAssetCollection
        }) { success, error in
            DispatchQueue.main.async {
                if success, let id = albumPlaceholder?.localIdentifier {
                    self.currentAlbumIdentifier = id
                    completion(id)
                } else {
                    // Could not create album, clear current id to avoid stale state
                    self.currentAlbumIdentifier = nil
                    completion(nil)
                }
            }
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
            let processed = self.filmFilter.process(image: original) ?? original
            let text = await MainActor.run { self.watermarkText(for: displayCount) }
            let watermarked = await MainActor.run { self.addWatermark(to: processed, text: text) }

            // Encode as JPEG with reasonable quality
            let finalData = watermarked.jpegData(compressionQuality: 0.9) ?? data

            await MainActor.run {
                self.saveToPhotos(finalData)
            }
        }
    }
}

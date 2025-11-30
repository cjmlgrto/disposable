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

    // Persistent countdown
    @Published var remainingShots: Int {
        didSet {
            UserDefaults.standard.set(remainingShots, forKey: Self.remainingShotsKey)
        }
    }

    private static let remainingShotsKey = "remainingShots"
    private static let maxShots = 24

    override init() {
        let stored = UserDefaults.standard.object(forKey: Self.remainingShotsKey) as? Int
        self.remainingShots = stored ?? Self.maxShots
        super.init()
        // Normalize any invalid stored values
        if remainingShots <= 0 || remainingShots > Self.maxShots {
            remainingShots = Self.maxShots
        }
    }

    func start() async {
        let authorized = await requestPermissions()
        guard authorized else {
            errorMessage = "Camera and Photo Library permissions are required."
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
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
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
                        throw NSError(domain: "Camera", code: 1, userInfo: [NSLocalizedDescriptionKey: "No back camera available."])
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
                    self.errorMessage = "Save failed: \(error.localizedDescription)"
                    return
                }
                if success {
                    // Decrement only on successful save
                    if self.remainingShots > 0 {
                        self.remainingShots -= 1
                    }
                    // Auto-reset when reaching zero so the next shot starts a fresh roll
                    if self.remainingShots == 0 {
                        // Do not immediately reset here if you prefer showing 0 until the next press.
                        // The requirement says "When it reaches zero, reset it." so we reset now.
                        self.remainingShots = Self.maxShots
                    }
                }
            }
        }
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
        DispatchQueue.main.async { self.saveToPhotos(data) }
    }
}

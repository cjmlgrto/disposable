import SwiftUI
import AVFoundation

public struct CameraPreviewView: View {
    public let session: AVCaptureSession?

    public init(session: AVCaptureSession?) {
        self.session = session
    }

    public var body: some View {
        PreviewLayerView(session: session)
            .clipped()
    }

    private struct PreviewLayerView: UIViewRepresentable {
        let session: AVCaptureSession?

        func makeUIView(context: Context) -> PreviewContainerView {
            let view = PreviewContainerView()
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            view.videoPreviewLayer.session = session
            return view
        }

        func updateUIView(_ uiView: PreviewContainerView, context: Context) {
            // Update the session if it changes
            uiView.videoPreviewLayer.session = session
        }
    }
}

private final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

#Preview("CameraPreviewView") {
    // Design-time preview: use an empty session; won't show video in previews
    CameraPreviewView(session: AVCaptureSession())
        .frame(width: 80, height: 58)
}

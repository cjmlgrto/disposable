// FunSaverFilter.swift
// Film emulation Core Image filter for the disposable camera app
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

final class FunSaverFilter {
    private let context = CIContext()

    func apply(to input: CIImage) -> CIImage {
        var img = input

        // 1) Exposure + saturation (Gold 400 vibe)
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = img
        colorControls.saturation = 1.18
        colorControls.contrast = 1.10
        colorControls.brightness = 0.03
        img = colorControls.outputImage ?? img

        // 2) Tone curve (lift blacks, protect highlights)
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = img
        toneCurve.point0 = CGPoint(x: 0.00, y: 0.05) // lifted blacks
        toneCurve.point1 = CGPoint(x: 0.25, y: 0.28)
        toneCurve.point2 = CGPoint(x: 0.50, y: 0.55)
        toneCurve.point3 = CGPoint(x: 0.75, y: 0.83)
        toneCurve.point4 = CGPoint(x: 1.00, y: 0.97) // soft highlights
        img = toneCurve.outputImage ?? img

        // 3) Warm bias (yellow/red lean)
        let tempTint = CIFilter.temperatureAndTint()
        tempTint.inputImage = img
        tempTint.neutral = CIVector(x: 6500, y: 0)
        tempTint.targetNeutral = CIVector(x: 7200, y: 0)
        img = tempTint.outputImage ?? img

        // 4) Subtle color cross-talk (greens + reds pop)
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = img
        colorMatrix.rVector = CIVector(x: 1.05, y: 0.02, z: 0.00, w: 0)
        colorMatrix.gVector = CIVector(x: 0.00, y: 1.02, z: 0.00, w: 0)
        colorMatrix.bVector = CIVector(x: 0.00, y: 0.00, z: 0.96, w: 0)
        colorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        img = colorMatrix.outputImage ?? img

        // 5) Grain (cheap 35mm feel)
        if let noise = CIFilter.randomGenerator().outputImage?.cropped(to: img.extent) {
            let grainControls = CIFilter.colorControls()
            grainControls.inputImage = noise
            grainControls.saturation = 0
            grainControls.contrast = 1.1
            grainControls.brightness = -0.1

            let blend = CIFilter.overlayBlendMode()
            blend.inputImage = grainControls.outputImage
            blend.backgroundImage = img
            img = blend.outputImage ?? img
        }

        // 6) Vignette (plastic lens + flash falloff)
        let vignette = CIFilter.vignette()
        vignette.inputImage = img
        vignette.intensity = 0.45
        vignette.radius = Float(min(img.extent.width, img.extent.height) * 0.7)
        img = vignette.outputImage ?? img

        // 7) Edge softness (cheap lens)
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = img
        blur.radius = 0.6

        let blendSoft = CIFilter.softLightBlendMode()
        blendSoft.inputImage = blur.outputImage
        blendSoft.backgroundImage = img
        img = blendSoft.outputImage ?? img

        return img
    }

    func process(image: UIImage) -> UIImage? {
        guard let ciInput = image.ciImage ?? CIImage(image: image) else {
            return nil
        }
        let outputCI = apply(to: ciInput)
        guard let cgImage = context.createCGImage(outputCI, from: outputCI.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

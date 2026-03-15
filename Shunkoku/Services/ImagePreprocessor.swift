import CoreImage
import UIKit

/// 画像前処理 — OCR精度向上のためのコントラスト強調・リサイズ
enum ImagePreprocessor {
    private static let context = CIContext()

    /// UIImageをOCR用に前処理
    static func preprocess(_ image: UIImage) -> CGImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        var processed = ciImage

        // リサイズ（長辺を制限）
        let maxDim = Constants.ImagePreprocess.maxDimension
        let size = processed.extent.size
        if size.width > maxDim || size.height > maxDim {
            let scale = min(maxDim / size.width, maxDim / size.height)
            processed = processed.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        }

        // コントラスト強調
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(processed, forKey: kCIInputImageKey)
            filter.setValue(Constants.ImagePreprocess.contrastFactor, forKey: kCIInputContrastKey)
            filter.setValue(0.0, forKey: kCIInputBrightnessKey)
            if let output = filter.outputImage {
                processed = output
            }
        }

        // シャープネス強調
        if let filter = CIFilter(name: "CISharpenLuminance") {
            filter.setValue(processed, forKey: kCIInputImageKey)
            filter.setValue(0.5, forKey: kCIInputSharpnessKey)
            if let output = filter.outputImage {
                processed = output
            }
        }

        return context.createCGImage(processed, from: processed.extent)
    }

    /// UIImageからCGImageへ変換（前処理なし）
    static func toCGImage(_ image: UIImage) -> CGImage? {
        image.cgImage
    }
}

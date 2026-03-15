import Vision
import UIKit

/// OCR認識結果（バウンディングボックス付き）
struct OCRTextBlock: Sendable {
    let text: String
    let confidence: Float
    /// 正規化座標（左下原点）
    let boundingBox: CGRect
}

/// Vision FrameworkによるOCR処理
actor OCRService {
    /// 単一画像のOCR実行
    func recognizeText(in image: CGImage) async throws -> [OCRTextBlock] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let blocks = observations.compactMap { observation -> OCRTextBlock? in
                    guard let candidate = observation.topCandidates(1).first,
                          candidate.confidence >= Constants.OCR.minimumConfidence else {
                        return nil
                    }
                    return OCRTextBlock(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                continuation.resume(returning: blocks)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = Constants.OCR.recognitionLanguages
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// 複数画像の並行OCR処理
    func recognizeText(in images: [CGImage]) async throws -> [[OCRTextBlock]] {
        try await withThrowingTaskGroup(of: (Int, [OCRTextBlock]).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let blocks = try await self.recognizeText(in: image)
                    return (index, blocks)
                }
            }

            var results = Array(repeating: [OCRTextBlock](), count: images.count)
            for try await (index, blocks) in group {
                results[index] = blocks
            }
            return results
        }
    }

    /// UIImageからOCR実行（前処理込み）
    func recognizeText(in image: UIImage) async throws -> [OCRTextBlock] {
        guard let cgImage = ImagePreprocessor.preprocess(image) ?? image.cgImage else {
            throw OCRError.invalidImage
        }
        return try await recognizeText(in: cgImage)
    }

    /// 複数UIImageからOCR実行（前処理込み）
    func recognizeText(in images: [UIImage]) async throws -> [[OCRTextBlock]] {
        let cgImages = images.compactMap { ImagePreprocessor.preprocess($0) ?? $0.cgImage }
        guard cgImages.count == images.count else {
            throw OCRError.invalidImage
        }
        return try await recognizeText(in: cgImages)
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像の読み込みに失敗しました"
        case .recognitionFailed(let detail):
            return "文字認識に失敗しました: \(detail)"
        }
    }
}

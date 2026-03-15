import SwiftUI
import PhotosUI
import SwiftData

/// スキャンフローのオーケストレーション
@Observable
@MainActor
final class ScanViewModel {
    // MARK: - State
    var selectedSourceType: SourceType = .creditCard
    var selectedPhotos: [PhotosPickerItem] = []
    var loadedImages: [UIImage] = []

    var isProcessing = false
    var processingProgress: Double = 0
    var processingStatus = ""

    var parsedTransactions: [EditableTransaction] = []
    var rawOCRText = ""

    var error: String?
    var showError = false
    var isComplete = false

    // MARK: - Services
    private let ocrService = OCRService()
    private let parsingService = ParsingService()

    // MARK: - Editable Transaction (UI用中間モデル)
    struct EditableTransaction: Identifiable {
        let id = UUID()
        var date: Date
        var amount: Int
        var counterpartyName: String
        var memo: String
        var category: AccountCategory
        var taxRate: TaxRate
        var transactionType: TransactionType
        var classificationReason: String
    }

    // MARK: - Pipeline

    /// 選択された写真を読み込み
    func loadImages() async {
        loadedImages = []
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loadedImages.append(image)
            }
        }
    }

    /// メインパイプライン: 画像 → OCR → パース → 分類 → 編集可能な取引データ
    func processImages(modelContext: ModelContext) async {
        guard !loadedImages.isEmpty else {
            error = "画像が選択されていません"
            showError = true
            return
        }

        isProcessing = true
        processingProgress = 0
        parsedTransactions = []
        error = nil

        do {
            // Step 1: OCR
            processingStatus = "文字を認識中..."
            processingProgress = 0.2

            let allBlocks = try await ocrService.recognizeText(in: loadedImages)
            rawOCRText = allBlocks.flatMap { blocks in
                blocks.map(\.text)
            }.joined(separator: "\n")

            // Step 2: パース
            processingStatus = "取引データを解析中..."
            processingProgress = 0.5

            var allParsed: [ParsedTransaction] = []
            for blocks in allBlocks {
                let parsed = await parsingService.parse(blocks: blocks, sourceType: selectedSourceType)
                allParsed.append(contentsOf: parsed)
            }

            // Step 3: 分類
            processingStatus = "勘定科目を分類中..."
            processingProgress = 0.7

            let classificationService = ClassificationService(modelContext: modelContext)

            var editableList: [EditableTransaction] = []
            for parsed in allParsed {
                let request = TransactionClassificationRequest(
                    counterpartyName: parsed.description,
                    amount: parsed.amount,
                    memo: parsed.memo,
                    sourceType: selectedSourceType.rawValue
                )
                let (category, taxRate, reason) = await classificationService.classify(request)

                editableList.append(EditableTransaction(
                    date: parsed.date ?? Date(),
                    amount: parsed.amount,
                    counterpartyName: parsed.description,
                    memo: parsed.memo,
                    category: category,
                    taxRate: parsed.taxRate ?? taxRate,
                    transactionType: parsed.transactionType,
                    classificationReason: reason
                ))
            }

            parsedTransactions = editableList
            processingProgress = 1.0
            processingStatus = "\(editableList.count)件の取引を検出しました"

        } catch {
            self.error = error.localizedDescription
            showError = true
        }

        isProcessing = false
    }

    /// 編集後の取引データをSwiftDataに保存
    func saveTransactions(modelContext: ModelContext) {
        // バッチ作成
        let imageDataList = loadedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
        let batch = TransactionBatch(
            sourceType: selectedSourceType,
            imageDataList: imageDataList,
            rawOCRText: rawOCRText
        )
        modelContext.insert(batch)

        // 各取引を保存
        for editable in parsedTransactions {
            let transaction = Transaction(
                date: editable.date,
                amount: editable.amount,
                counterpartyName: editable.counterpartyName,
                memo: editable.memo,
                category: editable.category,
                taxRate: editable.taxRate,
                transactionType: editable.transactionType,
                sourceType: selectedSourceType,
                isConfirmed: false,
                batch: batch
            )
            modelContext.insert(transaction)
        }

        try? modelContext.save()
        isComplete = true
    }

    /// 状態をリセット
    func reset() {
        selectedPhotos = []
        loadedImages = []
        isProcessing = false
        processingProgress = 0
        processingStatus = ""
        parsedTransactions = []
        rawOCRText = ""
        error = nil
        showError = false
        isComplete = false
    }
}

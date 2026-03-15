import Foundation
import SwiftData

@Model
final class TransactionBatch {
    var id: UUID
    /// スキャン日時
    var scannedAt: Date
    /// 元画像データ（複数枚対応）
    var imageDataList: [Data]
    /// OCR生テキスト
    var rawOCRText: String
    /// ソース種別
    var sourceTypeRawValue: String

    @Relationship(deleteRule: .cascade, inverse: \Transaction.batch)
    var transactions: [Transaction]

    var sourceType: SourceType {
        get { SourceType(rawValue: sourceTypeRawValue) ?? .creditCard }
        set { sourceTypeRawValue = newValue.rawValue }
    }

    var transactionCount: Int { transactions.count }

    init(
        sourceType: SourceType,
        imageDataList: [Data] = [],
        rawOCRText: String = ""
    ) {
        self.id = UUID()
        self.scannedAt = Date()
        self.imageDataList = imageDataList
        self.rawOCRText = rawOCRText
        self.sourceTypeRawValue = sourceType.rawValue
        self.transactions = []
    }
}

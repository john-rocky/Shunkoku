import Foundation
import FoundationModels

/// AI分類リクエスト用の構造体
struct TransactionClassificationRequest: Sendable {
    let counterpartyName: String
    let amount: Int
    let memo: String
    let sourceType: String
}

/// AI分類結果 — Foundation Models の @Generable で構造化出力
@Generable
struct TransactionClassification {
    /// 勘定科目（日本語）
    @Guide(description: "勘定科目を以下から1つ選択: 旅費交通費, 通信費, 消耗品費, 接待交際費, 地代家賃, 水道光熱費, 広告宣伝費, 外注工賃, 福利厚生費, 雑費, 事務用品費, 修繕費, 保険料, 車両費, 新聞図書費, 会議費, 研修費, 諸会費, 租税公課, 売上高, 雑収入")
    var category: String

    /// 税率
    @Guide(description: "消費税率を選択: 10%, 8%, 非課税")
    var taxRate: String

    /// 分類理由（短い説明）
    @Guide(description: "この分類にした理由を1行で簡潔に説明")
    var reason: String
}

/// バッチ分類用 — 複数取引を一度に分類
@Generable
struct BatchClassificationResult {
    @Guide(description: "各取引の分類結果リスト")
    var classifications: [TransactionClassification]
}

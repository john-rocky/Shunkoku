import Foundation
import SwiftData

@Model
final class CategoryMapping {
    var id: UUID
    /// マッチングキーワード
    var keyword: String
    /// マッピング先の勘定科目
    var categoryRawValue: String
    /// マッピング先の税率（オプション）
    var taxRateRawValue: String?
    /// ユーザー定義かAI提案か
    var isUserDefined: Bool
    /// 使用回数（優先度に使用）
    var usageCount: Int

    var category: AccountCategory {
        get { AccountCategory(rawValue: categoryRawValue) ?? .miscellaneousExpense }
        set { categoryRawValue = newValue.rawValue }
    }

    var taxRate: TaxRate? {
        get {
            guard let raw = taxRateRawValue else { return nil }
            return TaxRate(rawValue: raw)
        }
        set { taxRateRawValue = newValue?.rawValue }
    }

    init(
        keyword: String,
        category: AccountCategory,
        taxRate: TaxRate? = nil,
        isUserDefined: Bool = false
    ) {
        self.id = UUID()
        self.keyword = keyword.lowercased()
        self.categoryRawValue = category.rawValue
        self.taxRateRawValue = taxRate?.rawValue
        self.isUserDefined = isUserDefined
        self.usageCount = 0
    }
}

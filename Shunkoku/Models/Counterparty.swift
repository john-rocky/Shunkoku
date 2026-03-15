import Foundation
import SwiftData

@Model
final class Counterparty {
    var id: UUID
    /// 正式名称
    var name: String
    /// OCR表記ゆれに対応するエイリアス
    var aliases: [String]
    /// デフォルト勘定科目
    var defaultCategoryRawValue: String?
    /// デフォルト税率
    var defaultTaxRateRawValue: String?

    @Relationship(deleteRule: .nullify, inverse: \Transaction.counterparty)
    var transactions: [Transaction]

    var defaultCategory: AccountCategory? {
        get {
            guard let raw = defaultCategoryRawValue else { return nil }
            return AccountCategory(rawValue: raw)
        }
        set { defaultCategoryRawValue = newValue?.rawValue }
    }

    var defaultTaxRate: TaxRate? {
        get {
            guard let raw = defaultTaxRateRawValue else { return nil }
            return TaxRate(rawValue: raw)
        }
        set { defaultTaxRateRawValue = newValue?.rawValue }
    }

    init(name: String, aliases: [String] = [], defaultCategory: AccountCategory? = nil) {
        self.id = UUID()
        self.name = name
        self.aliases = aliases
        self.defaultCategoryRawValue = defaultCategory?.rawValue
        self.transactions = []
    }

    /// 名前またはエイリアスに含まれるかチェック
    func matches(_ text: String) -> Bool {
        let normalized = text.lowercased()
        if name.lowercased().contains(normalized) || normalized.contains(name.lowercased()) {
            return true
        }
        return aliases.contains { alias in
            alias.lowercased().contains(normalized) || normalized.contains(alias.lowercased())
        }
    }
}

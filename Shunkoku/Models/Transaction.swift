import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var date: Date
    /// 金額（円単位、正の整数）
    var amount: Int
    var counterpartyName: String
    var memo: String

    /// 勘定科目（rawValue保存）
    var categoryRawValue: String
    /// 税率（rawValue保存）
    var taxRateRawValue: String
    /// 収支区分（rawValue保存）
    var transactionTypeRawValue: String
    /// ソース種別（rawValue保存）
    var sourceTypeRawValue: String

    /// ユーザーが確認済みかどうか
    var isConfirmed: Bool

    /// 作成日時
    var createdAt: Date

    // MARK: - Relationships
    var batch: TransactionBatch?
    var counterparty: Counterparty?

    // MARK: - Computed Properties
    var category: AccountCategory {
        get { AccountCategory(rawValue: categoryRawValue) ?? .miscellaneousExpense }
        set { categoryRawValue = newValue.rawValue }
    }

    var taxRate: TaxRate {
        get { TaxRate(rawValue: taxRateRawValue) ?? .standard }
        set { taxRateRawValue = newValue.rawValue }
    }

    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .expense }
        set { transactionTypeRawValue = newValue.rawValue }
    }

    var sourceType: SourceType {
        get { SourceType(rawValue: sourceTypeRawValue) ?? .creditCard }
        set { sourceTypeRawValue = newValue.rawValue }
    }

    init(
        date: Date,
        amount: Int,
        counterpartyName: String,
        memo: String = "",
        category: AccountCategory = .miscellaneousExpense,
        taxRate: TaxRate = .standard,
        transactionType: TransactionType = .expense,
        sourceType: SourceType = .creditCard,
        isConfirmed: Bool = false,
        batch: TransactionBatch? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.counterpartyName = counterpartyName
        self.memo = memo
        self.categoryRawValue = category.rawValue
        self.taxRateRawValue = taxRate.rawValue
        self.transactionTypeRawValue = transactionType.rawValue
        self.sourceTypeRawValue = sourceType.rawValue
        self.isConfirmed = isConfirmed
        self.createdAt = Date()
        self.batch = batch
    }
}

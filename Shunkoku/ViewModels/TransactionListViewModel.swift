import SwiftUI
import SwiftData

/// 取引一覧画面のViewModel
@Observable
@MainActor
final class TransactionListViewModel {
    var selectedType: TransactionType = .expense
    var selectedMonth: Date?
    var selectedCategory: AccountCategory?
    var selectedSourceType: SourceType?
    var searchText = ""

    /// フィルタ条件に基づくFetchDescriptor
    var fetchDescriptor: FetchDescriptor<Transaction> {
        var predicates: [Predicate<Transaction>] = []

        // 収支区分
        let typeRaw = selectedType.rawValue
        predicates.append(#Predicate { $0.transactionTypeRawValue == typeRaw })

        // 月フィルタ
        if let month = selectedMonth {
            let calendar = Calendar(identifier: .gregorian)
            let start = calendar.startOfMonth(for: month)
            if let end = calendar.date(byAdding: .month, value: 1, to: start) {
                predicates.append(#Predicate { $0.date >= start && $0.date < end })
            }
        }

        // 科目フィルタ
        if let category = selectedCategory {
            let catRaw = category.rawValue
            predicates.append(#Predicate { $0.categoryRawValue == catRaw })
        }

        // ソースフィルタ
        if let source = selectedSourceType {
            let srcRaw = source.rawValue
            predicates.append(#Predicate { $0.sourceTypeRawValue == srcRaw })
        }

        // 検索
        if !searchText.isEmpty {
            let query = searchText
            predicates.append(#Predicate {
                $0.counterpartyName.localizedStandardContains(query) ||
                $0.memo.localizedStandardContains(query)
            })
        }

        // Predicateの結合
        let combined = predicates.reduce(into: #Predicate<Transaction> { _ in true }) { result, next in
            result = #Predicate { item in
                result.evaluate(item) && next.evaluate(item)
            }
        }

        var descriptor = FetchDescriptor<Transaction>(
            predicate: combined,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 500

        return descriptor
    }

    /// 月選択用の利用可能月リスト生成
    static func availableMonths(from transactions: [Transaction]) -> [Date] {
        let calendar = Calendar(identifier: .gregorian)
        let months = Set(transactions.map { calendar.startOfMonth(for: $0.date) })
        return months.sorted(by: >)
    }

    /// 選択中の取引を削除
    func deleteTransactions(_ transactions: [Transaction], modelContext: ModelContext) {
        for tx in transactions {
            modelContext.delete(tx)
        }
        try? modelContext.save()
    }

    /// 取引の確認状態をトグル
    func toggleConfirmation(_ transaction: Transaction, modelContext: ModelContext) {
        transaction.isConfirmed.toggle()
        try? modelContext.save()
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

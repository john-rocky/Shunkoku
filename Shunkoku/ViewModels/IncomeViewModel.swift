import SwiftUI
import SwiftData

/// 収入管理画面のViewModel
@Observable
@MainActor
final class IncomeViewModel {
    var searchText = ""
    var selectedMonth: Date?

    /// 取引先別の収入集計
    struct CounterpartySummary: Identifiable {
        let id = UUID()
        let name: String
        let totalAmount: Int
        let transactionCount: Int
    }

    /// 取引先別の収入サマリを取得
    func fetchCounterpartySummaries(modelContext: ModelContext) -> [CounterpartySummary] {
        let incomeRaw = TransactionType.income.rawValue
        var descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.transactionTypeRawValue == incomeRaw },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        if let month = selectedMonth {
            let calendar = Calendar(identifier: .gregorian)
            let start = calendar.startOfMonth(for: month)
            if let end = calendar.date(byAdding: .month, value: 1, to: start) {
                descriptor = FetchDescriptor<Transaction>(
                    predicate: #Predicate {
                        $0.transactionTypeRawValue == incomeRaw &&
                        $0.date >= start && $0.date < end
                    },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
            }
        }

        guard let transactions = try? modelContext.fetch(descriptor) else { return [] }

        var grouped: [String: (total: Int, count: Int)] = [:]
        for tx in transactions {
            let key = tx.counterpartyName
            if !searchText.isEmpty && !key.localizedStandardContains(searchText) { continue }
            let existing = grouped[key, default: (total: 0, count: 0)]
            grouped[key] = (total: existing.total + tx.amount, count: existing.count + 1)
        }

        return grouped.map { CounterpartySummary(name: $0.key, totalAmount: $0.value.total, transactionCount: $0.value.count) }
            .sorted { $0.totalAmount > $1.totalAmount }
    }
}

import SwiftUI
import SwiftData

/// ダッシュボード画面のViewModel
@Observable
@MainActor
final class DashboardViewModel {
    var selectedMonth: Date = Date()
    var monthlyExpense: Int = 0
    var monthlyIncome: Int = 0
    var unconfirmedCount: Int = 0
    var categoryBreakdown: [(category: AccountCategory, amount: Int)] = []

    /// 月次集計の更新
    func refresh(modelContext: ModelContext) {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfMonth(for: selectedMonth)
        guard let end = calendar.date(byAdding: .month, value: 1, to: start) else { return }

        // 月内の全取引を取得
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= start && $0.date < end }
        )

        guard let transactions = try? modelContext.fetch(descriptor) else { return }

        // 支出合計
        monthlyExpense = transactions
            .filter { $0.transactionType == .expense }
            .reduce(0) { $0 + $1.amount }

        // 収入合計
        monthlyIncome = transactions
            .filter { $0.transactionType == .income }
            .reduce(0) { $0 + $1.amount }

        // 未確認件数（月を問わず全体）
        let unconfirmedDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.isConfirmed == false }
        )
        unconfirmedCount = (try? modelContext.fetchCount(unconfirmedDescriptor)) ?? 0

        // 科目別内訳（支出のみ）
        let expenses = transactions.filter { $0.transactionType == .expense }
        var breakdown: [AccountCategory: Int] = [:]
        for tx in expenses {
            breakdown[tx.category, default: 0] += tx.amount
        }
        categoryBreakdown = breakdown
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $0.value) }
    }

    /// 前月に移動
    func previousMonth() {
        let calendar = Calendar(identifier: .gregorian)
        if let prev = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = prev
        }
    }

    /// 翌月に移動
    func nextMonth() {
        let calendar = Calendar(identifier: .gregorian)
        if let next = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = next
        }
    }
}

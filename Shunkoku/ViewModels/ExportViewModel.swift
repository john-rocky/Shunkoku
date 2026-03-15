import SwiftUI
import SwiftData

/// エクスポート画面のViewModel
@Observable
@MainActor
final class ExportViewModel {
    var selectedFormat: ExportFormat = .freee
    var encoding: CSVExportService.CSVEncoding = .shiftJIS
    var startDate: Date
    var endDate: Date
    var includeUnconfirmed = true

    var preview = ""
    var totalCount = 0
    var exportData: Data?
    var fileName = ""

    init() {
        // デフォルト: 現在の確定申告対象年度
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let fiscalYear = month <= 3 ? year - 1 : year

        self.startDate = calendar.date(from: DateComponents(year: fiscalYear, month: 1, day: 1)) ?? now
        self.endDate = calendar.date(from: DateComponents(year: fiscalYear, month: 12, day: 31)) ?? now
    }

    /// プレビュー生成
    func generatePreview(modelContext: ModelContext) {
        let transactions = fetchTransactions(modelContext: modelContext)
        totalCount = transactions.count
        preview = CSVExportService.preview(transactions: transactions, format: selectedFormat)
    }

    /// CSV生成
    func generateCSV(modelContext: ModelContext) {
        let transactions = fetchTransactions(modelContext: modelContext)
        totalCount = transactions.count
        exportData = CSVExportService.export(
            transactions: transactions,
            format: selectedFormat,
            encoding: encoding
        )
        fileName = CSVExportService.fileName(format: selectedFormat, startDate: startDate, endDate: endDate)
    }

    /// 条件に合う取引を取得
    private func fetchTransactions(modelContext: ModelContext) -> [Transaction] {
        let start = startDate
        let end = endDate

        var descriptor: FetchDescriptor<Transaction>
        if includeUnconfirmed {
            descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.date >= start && $0.date <= end },
                sortBy: [SortDescriptor(\.date)]
            )
        } else {
            descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.date >= start && $0.date <= end && $0.isConfirmed == true },
                sortBy: [SortDescriptor(\.date)]
            )
        }

        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

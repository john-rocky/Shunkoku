import Foundation

/// CSV出力サービス
enum CSVExportService {

    // MARK: - Public Interface

    /// 取引データをCSVに変換
    static func export(
        transactions: [Transaction],
        format: ExportFormat,
        encoding: CSVEncoding = .shiftJIS
    ) -> Data? {
        let csvString: String
        switch format {
        case .freee:
            csvString = generateFreeeCSV(transactions: transactions)
        case .yayoi:
            csvString = generateYayoiCSV(transactions: transactions)
        }

        return encode(csvString, encoding: encoding)
    }

    /// プレビュー用の文字列取得
    static func preview(
        transactions: [Transaction],
        format: ExportFormat,
        maxRows: Int = 5
    ) -> String {
        let limited = Array(transactions.prefix(maxRows))
        switch format {
        case .freee:
            return generateFreeeCSV(transactions: limited)
        case .yayoi:
            return generateYayoiCSV(transactions: limited)
        }
    }

    /// ファイル名生成
    static func fileName(format: ExportFormat, startDate: Date, endDate: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let start = df.string(from: startDate)
        let end = df.string(from: endDate)
        return "\(format.fileNamePrefix)_\(start)_\(end).csv"
    }

    // MARK: - freee Format

    /// freee形式CSV生成
    /// 列: 収支区分, 管理番号, 発生日, 決済期日, 取引先, 勘定科目, 税区分, 金額, 税計算区分, 税額, 備考
    private static func generateFreeeCSV(transactions: [Transaction]) -> String {
        var lines: [String] = []

        // ヘッダー
        lines.append("収支区分,管理番号,発生日,決済期日,取引先,勘定科目,税区分,金額,税計算区分,税額,備考")

        for tx in transactions {
            let type = tx.transactionType == .income ? "収入" : "支出"
            let date = DateFormatters.csvDate.string(from: tx.date)
            let counterparty = escapeCSV(tx.counterpartyName)
            let category = tx.category.displayName
            let taxLabel: String
            if tx.transactionType == .income {
                taxLabel = tx.taxRate.freeeTaxLabelSales
            } else {
                taxLabel = tx.taxRate.freeeTaxLabelPurchase
            }
            let amount = String(tx.amount)
            let memo = escapeCSV(tx.memo)

            lines.append("\(type),,\(date),,\(counterparty),\(category),\(taxLabel),\(amount),内税,,\(memo)")
        }

        return lines.joined(separator: "\r\n")
    }

    // MARK: - Yayoi Format

    /// 弥生会計形式CSV生成
    /// 列: 識別フラグ, 伝票No., 決算, 取引日付, 借方勘定科目, 借方補助科目, 借方部門, 借方税区分, 借方金額, 借方税金額,
    ///     貸方勘定科目, 貸方補助科目, 貸方部門, 貸方税区分, 貸方金額, 貸方税金額, 摘要, 番号, 期日, タイプ, 生成元, 仕訳メモ, 付箋1, 付箋2, 調整
    private static func generateYayoiCSV(transactions: [Transaction]) -> String {
        var lines: [String] = []

        // ヘッダーなし（弥生は通常ヘッダーなし、ただし識別行で開始）

        for tx in transactions {
            let date = DateFormatters.csvDate.string(from: tx.date)
            let debitAccount: String
            let creditAccount: String
            let taxCode: String

            if tx.transactionType == .income {
                // 収入: 借方=普通預金、貸方=勘定科目
                debitAccount = "普通預金"
                creditAccount = tx.category.displayName
                taxCode = tx.taxRate.yayoiTaxCodeSales
            } else {
                // 支出: 借方=勘定科目、貸方=事業主借
                debitAccount = tx.category.displayName
                creditAccount = tx.category.defaultCounterAccount
                taxCode = tx.taxRate.yayoiTaxCodePurchase
            }

            let amount = String(tx.amount)
            let description = escapeCSV("\(tx.counterpartyName) \(tx.memo)".trimmingCharacters(in: .whitespaces))

            // 弥生仕訳インポート形式
            let fields = [
                "2000",           // 識別フラグ
                "",               // 伝票No.
                "",               // 決算
                date,             // 取引日付
                debitAccount,     // 借方勘定科目
                "",               // 借方補助科目
                "",               // 借方部門
                taxCode,          // 借方税区分
                amount,           // 借方金額
                "",               // 借方税金額
                creditAccount,    // 貸方勘定科目
                "",               // 貸方補助科目
                "",               // 貸方部門
                "",               // 貸方税区分
                amount,           // 貸方金額
                "",               // 貸方税金額
                description,      // 摘要
                "",               // 番号
                "",               // 期日
                "0",              // タイプ
                "",               // 生成元
                "",               // 仕訳メモ
                "0",              // 付箋1
                "0",              // 付箋2
                "no",             // 調整
            ]

            lines.append(fields.joined(separator: ","))
        }

        return lines.joined(separator: "\r\n")
    }

    // MARK: - Encoding

    enum CSVEncoding {
        case shiftJIS
        case utf8BOM

        var displayName: String {
            switch self {
            case .shiftJIS: return "Shift-JIS"
            case .utf8BOM: return "UTF-8 (BOM付き)"
            }
        }
    }

    private static func encode(_ string: String, encoding: CSVEncoding) -> Data? {
        switch encoding {
        case .shiftJIS:
            return string.data(using: Constants.CSV.shiftJISEncoding)
                ?? string.data(using: .shiftJIS)
        case .utf8BOM:
            guard let utf8Data = string.data(using: .utf8) else { return nil }
            return Constants.CSV.utf8BOM + utf8Data
        }
    }

    // MARK: - Helpers

    private static func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
}

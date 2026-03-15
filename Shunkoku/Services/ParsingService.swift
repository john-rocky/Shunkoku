import Foundation

/// パース結果（1行の取引データ）
struct ParsedTransaction: Sendable {
    var date: Date?
    var amount: Int
    var description: String
    var transactionType: TransactionType
    var taxRate: TaxRate?
    var memo: String

    init(
        date: Date? = nil,
        amount: Int = 0,
        description: String = "",
        transactionType: TransactionType = .expense,
        taxRate: TaxRate? = nil,
        memo: String = ""
    ) {
        self.date = date
        self.amount = amount
        self.description = description
        self.transactionType = transactionType
        self.taxRate = taxRate
        self.memo = memo
    }
}

/// ソース種別ごとのOCRテキスト解析
actor ParsingService {

    // MARK: - Public Interface

    /// OCRブロックをソース種別に応じてパース
    func parse(blocks: [OCRTextBlock], sourceType: SourceType) -> [ParsedTransaction] {
        switch sourceType {
        case .creditCard:
            return parseCreditCard(blocks: blocks)
        case .bankStatement:
            return parseBankStatement(blocks: blocks)
        case .receipt:
            return parseReceipt(blocks: blocks)
        }
    }

    /// 生テキストの結合（バッチ保存用）
    func rawText(from blocks: [OCRTextBlock]) -> String {
        blocks.map(\.text).joined(separator: "\n")
    }

    // MARK: - Credit Card Parsing

    /// クレジットカード明細のパース
    /// Y座標でテキストを行にグループ化 → X座標で列特定
    private func parseCreditCard(blocks: [OCRTextBlock]) -> [ParsedTransaction] {
        let rows = groupIntoRows(blocks: blocks)
        var transactions: [ParsedTransaction] = []

        for row in rows {
            // ヘッダー行・合計行をスキップ
            let rowText = row.map(\.text).joined(separator: " ")
            if isHeaderRow(rowText) || isTotalRow(rowText) { continue }

            let parsed = parseTableRow(columns: row)
            if parsed.amount > 0 {
                transactions.append(parsed)
            }
        }

        return transactions
    }

    // MARK: - Bank Statement Parsing

    /// 銀行明細のパース
    private func parseBankStatement(blocks: [OCRTextBlock]) -> [ParsedTransaction] {
        // 半角カナを全角に変換
        let converted = blocks.map { block in
            OCRTextBlock(
                text: HalfWidthKanaConverter.toFullWidth(block.text),
                confidence: block.confidence,
                boundingBox: block.boundingBox
            )
        }

        let rows = groupIntoRows(blocks: converted)
        var transactions: [ParsedTransaction] = []

        for row in rows {
            let rowText = row.map(\.text).joined(separator: " ")
            if isHeaderRow(rowText) || isTotalRow(rowText) { continue }

            var parsed = parseTableRow(columns: row)

            // 入金/出金の判別
            if Constants.ParseKeywords.bankDepositKeywords.contains(where: { rowText.contains($0) }) {
                parsed.transactionType = .income
            } else {
                parsed.transactionType = .expense
            }

            if parsed.amount > 0 {
                transactions.append(parsed)
            }
        }

        return transactions
    }

    // MARK: - Receipt Parsing

    /// レシートのパース（店名・日付・合計・税率内訳）
    private func parseReceipt(blocks: [OCRTextBlock]) -> [ParsedTransaction] {
        guard !blocks.isEmpty else { return [] }

        // ブロックをY座標（上から下）でソート
        let sorted = blocks.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }

        // 店名: 上部のテキスト
        let storeName = sorted.first?.text ?? "不明"

        // 日付: 正規表現で検索
        let date = findDate(in: sorted)

        // 合計金額: 「合計」キーワード近辺
        let total = findTotal(in: sorted)

        // 税率内訳
        let taxRate = findTaxRate(in: sorted)

        if total > 0 {
            return [ParsedTransaction(
                date: date,
                amount: total,
                description: storeName,
                transactionType: .expense,
                taxRate: taxRate
            )]
        }

        return []
    }

    // MARK: - Helpers

    /// Y座標でテキストブロックを行にグループ化
    private func groupIntoRows(blocks: [OCRTextBlock]) -> [[OCRTextBlock]] {
        guard !blocks.isEmpty else { return [] }

        // Y座標（上から下: maxYが大きい方が上）でソート
        let sorted = blocks.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }

        var rows: [[OCRTextBlock]] = []
        var currentRow: [OCRTextBlock] = [sorted[0]]
        var currentY = sorted[0].boundingBox.midY

        let yThreshold: CGFloat = 0.015 // 同一行とみなすY座標の閾値

        for block in sorted.dropFirst() {
            if abs(block.boundingBox.midY - currentY) < yThreshold {
                currentRow.append(block)
            } else {
                // X座標でソート（左から右）して行を確定
                rows.append(currentRow.sorted { $0.boundingBox.minX < $1.boundingBox.minX })
                currentRow = [block]
                currentY = block.boundingBox.midY
            }
        }
        if !currentRow.isEmpty {
            rows.append(currentRow.sorted { $0.boundingBox.minX < $1.boundingBox.minX })
        }

        return rows
    }

    /// テーブル行を解析して取引データに変換
    private func parseTableRow(columns: [OCRTextBlock]) -> ParsedTransaction {
        var transaction = ParsedTransaction()
        var descriptionParts: [String] = []

        for block in columns {
            let text = block.text.trimmingCharacters(in: .whitespaces)

            // 日付の検出
            if transaction.date == nil, let date = DateFormatters.parseFromOCR(text) {
                transaction.date = date
                continue
            }

            // 金額の検出
            if let amount = CurrencyFormatters.parseAmount(text), amount != 0 {
                transaction.amount = abs(amount)
                if amount < 0 {
                    transaction.transactionType = .income
                }
                continue
            }

            // それ以外は取引先名/説明
            if !text.isEmpty {
                descriptionParts.append(text)
            }
        }

        transaction.description = descriptionParts.joined(separator: " ")
        return transaction
    }

    /// ヘッダー行の判定
    private func isHeaderRow(_ text: String) -> Bool {
        let keywords = Constants.ParseKeywords.cardHeaderKeywords
            + Constants.ParseKeywords.cardAmountKeywords
            + Constants.ParseKeywords.cardDescriptionKeywords
        let matchCount = keywords.filter { text.contains($0) }.count
        return matchCount >= 2
    }

    /// 合計行の判定
    private func isTotalRow(_ text: String) -> Bool {
        Constants.ParseKeywords.receiptTotalKeywords.contains { text.contains($0) }
            && !text.contains("対象")
    }

    /// レシートから日付を検索
    private func findDate(in blocks: [OCRTextBlock]) -> Date? {
        let datePattern = #"\d{4}[/\-年]\d{1,2}[/\-月]\d{1,2}日?"#
        let shortPattern = #"\d{1,2}[/\-月]\d{1,2}日?"#

        for block in blocks {
            if let match = block.text.range(of: datePattern, options: .regularExpression) {
                let dateStr = String(block.text[match])
                if let date = DateFormatters.parseFromOCR(dateStr) {
                    return date
                }
            }
            if let match = block.text.range(of: shortPattern, options: .regularExpression) {
                let dateStr = String(block.text[match])
                if let date = DateFormatters.parseFromOCR(dateStr) {
                    return date
                }
            }
        }
        return nil
    }

    /// レシートから合計金額を検索
    private func findTotal(in blocks: [OCRTextBlock]) -> Int {
        let amountPattern = #"[¥￥]?\s*[\d,]+円?"#

        for (index, block) in blocks.enumerated() {
            let text = block.text
            if Constants.ParseKeywords.receiptTotalKeywords.contains(where: { text.contains($0) }) {
                // 同じブロック内の金額を検出
                if let match = text.range(of: amountPattern, options: .regularExpression),
                   let amount = CurrencyFormatters.parseAmount(String(text[match])) {
                    return abs(amount)
                }
                // 次のブロック（右隣 or 直下）にある金額
                if index + 1 < blocks.count,
                   let amount = CurrencyFormatters.parseAmount(blocks[index + 1].text) {
                    return abs(amount)
                }
            }
        }

        // フォールバック: 最大金額を合計とみなす
        var maxAmount = 0
        for block in blocks {
            if let amount = CurrencyFormatters.parseAmount(block.text), abs(amount) > maxAmount {
                maxAmount = abs(amount)
            }
        }
        return maxAmount
    }

    /// レシートから税率情報を検索
    private func findTaxRate(in blocks: [OCRTextBlock]) -> TaxRate? {
        let allText = blocks.map(\.text).joined(separator: " ")

        let has10 = Constants.ParseKeywords.receiptTax10Keywords.contains { allText.contains($0) }
        let has8 = Constants.ParseKeywords.receiptTax8Keywords.contains { allText.contains($0) }

        if has8 && !has10 {
            return .reduced
        }
        // デフォルトは10%（混在時も10%として処理、詳細は手動確認）
        return .standard
    }
}

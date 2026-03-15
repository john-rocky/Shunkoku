import Foundation

enum CurrencyFormatters {
    /// 通貨表示: "¥1,234"
    static let yen: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "ja_JP")
        f.maximumFractionDigits = 0
        return f
    }()

    /// カンマ区切り: "1,234"
    static let withComma: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    /// 金額を表示文字列に変換
    static func displayYen(_ amount: Int) -> String {
        yen.string(from: NSNumber(value: amount)) ?? "¥\(amount)"
    }

    /// OCRテキストから金額を解析
    /// "1,234円", "¥1,234", "1234", "-1,234" などに対応
    static func parseAmount(_ text: String) -> Int? {
        var cleaned = text
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: "円", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .trimmingCharacters(in: .whitespaces)

        // マイナス記号の正規化
        cleaned = cleaned.replacingOccurrences(of: "−", with: "-")
        cleaned = cleaned.replacingOccurrences(of: "ー", with: "-")
        cleaned = cleaned.replacingOccurrences(of: "―", with: "-")

        return Int(cleaned)
    }
}

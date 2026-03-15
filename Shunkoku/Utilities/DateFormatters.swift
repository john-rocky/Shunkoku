import Foundation

enum DateFormatters {
    /// 表示用: "2024年3月15日"
    static let displayFull: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .long
        return f
    }()

    /// 表示用: "3/15"
    static let displayShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d"
        return f
    }()

    /// 表示用: "2024年3月"
    static let displayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f
    }()

    /// CSV出力用: "2024/03/15"
    static let csvDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    /// OCR解析用パターン（複数フォーマット対応）
    static let ocrParsers: [DateFormatter] = {
        let formats = [
            "yyyy/MM/dd",
            "yyyy/M/d",
            "yyyy年MM月dd日",
            "yyyy年M月d日",
            "MM/dd",
            "M/d",
            "R.MM.dd",    // 令和表記
        ]
        return formats.map { format in
            let f = DateFormatter()
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = format
            return f
        }
    }()

    /// OCRテキストから日付を解析（複数フォーマット試行）
    static func parseFromOCR(_ text: String, referenceYear: Int? = nil) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        for parser in ocrParsers {
            if let date = parser.date(from: trimmed) {
                // 年なしフォーマットの場合、参照年を設定
                let calendar = Calendar(identifier: .gregorian)
                let components = calendar.dateComponents([.year], from: date)
                if components.year == 2000 || components.year == 1, let refYear = referenceYear ?? currentFiscalYear() {
                    var adjusted = calendar.dateComponents([.month, .day], from: date)
                    adjusted.year = refYear
                    return calendar.date(from: adjusted)
                }
                return date
            }
        }
        return nil
    }

    /// 現在の確定申告対象年度を推定
    private static func currentFiscalYear() -> Int? {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        // 1-3月は前年度の確定申告期間
        return month <= 3 ? year - 1 : year
    }
}

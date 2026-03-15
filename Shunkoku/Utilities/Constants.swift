import Foundation

enum Constants {
    /// アプリ情報
    enum App {
        static let name = "瞬刻"
        static let bundleID = "com.daisukemajima.shuntoku"
    }

    /// OCR設定
    enum OCR {
        static let recognitionLanguages = ["ja-JP", "en-US"]
        static let minimumConfidence: Float = 0.3
    }

    /// 画像前処理
    enum ImagePreprocess {
        static let maxDimension: CGFloat = 4096
        static let contrastFactor: Float = 1.2
    }

    /// CSV出力
    enum CSV {
        static let shiftJISEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)
        ))
        static let utf8BOM = Data([0xEF, 0xBB, 0xBF])
    }

    /// パース用キーワード
    enum ParseKeywords {
        /// クレジットカード明細のヘッダー候補
        static let cardHeaderKeywords = ["利用日", "ご利用日", "日付", "お支払日"]
        static let cardAmountKeywords = ["利用金額", "ご利用金額", "金額", "お支払金額"]
        static let cardDescriptionKeywords = ["利用先", "ご利用先", "利用店名", "内容"]

        /// 銀行明細のキーワード
        static let bankDepositKeywords = ["入金", "お預入れ", "振込入金"]
        static let bankWithdrawalKeywords = ["出金", "お引出し", "振込出金", "引落"]

        /// レシートのキーワード
        static let receiptTotalKeywords = ["合計", "合　計", "お会計", "お買上合計", "小計"]
        static let receiptTax10Keywords = ["10%対象", "標準税率対象", "10%"]
        static let receiptTax8Keywords = ["8%対象", "軽減税率対象", "8%"]
    }

    /// 半角カナ→全角カナ変換テーブル
    static let halfWidthToFullWidthKana: [Character: Character] = {
        let half = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝ"
        let full = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
        var map: [Character: Character] = [:]
        for (h, f) in zip(half, full) {
            map[h] = f
        }
        return map
    }()
}

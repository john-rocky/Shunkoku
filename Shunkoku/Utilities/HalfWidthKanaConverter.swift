import Foundation

enum HalfWidthKanaConverter {
    /// 半角カナを全角カナに変換
    static func toFullWidth(_ text: String) -> String {
        // CFStringTransform を使って一括変換
        let mutable = NSMutableString(string: text)
        CFStringTransform(mutable, nil, kCFStringTransformFullwidthHalfwidth, true)
        return mutable as String
    }
}

import Foundation

/// スクリーンショットのソース種別
enum SourceType: String, CaseIterable, Codable, Identifiable, Sendable {
    case creditCard = "クレジットカード"
    case bankStatement = "銀行明細"
    case receipt = "レシート"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .creditCard: return "creditcard"
        case .bankStatement: return "building.columns"
        case .receipt: return "receipt"
        }
    }
}

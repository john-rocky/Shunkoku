import Foundation

/// 取引種別（収入/支出）
enum TransactionType: String, CaseIterable, Codable, Identifiable, Sendable {
    case expense = "支出"
    case income = "収入"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .expense: return "arrow.up.right"
        case .income: return "arrow.down.left"
        }
    }
}

import Foundation

/// 消費税率
enum TaxRate: String, CaseIterable, Codable, Identifiable, Sendable {
    case standard = "10%"
    case reduced = "8%"
    case exempt = "非課税"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var rate: Double {
        switch self {
        case .standard: return 0.10
        case .reduced: return 0.08
        case .exempt: return 0.0
        }
    }

    /// freee形式の税区分ラベル（仕入側）
    var freeeTaxLabelPurchase: String {
        switch self {
        case .standard: return "課対仕入10%"
        case .reduced: return "課対仕入8%（軽）"
        case .exempt: return "対象外"
        }
    }

    /// freee形式の税区分ラベル（売上側）
    var freeeTaxLabelSales: String {
        switch self {
        case .standard: return "課税売上10%"
        case .reduced: return "課税売上8%（軽）"
        case .exempt: return "対象外"
        }
    }

    /// 弥生形式の税区分コード（仕入側）
    var yayoiTaxCodePurchase: String {
        switch self {
        case .standard: return "課対仕入内10%"
        case .reduced: return "課対仕入内8%（軽）"
        case .exempt: return "対象外"
        }
    }

    /// 弥生形式の税区分コード（売上側）
    var yayoiTaxCodeSales: String {
        switch self {
        case .standard: return "課税売上内10%"
        case .reduced: return "課税売上内8%（軽）"
        case .exempt: return "対象外"
        }
    }
}

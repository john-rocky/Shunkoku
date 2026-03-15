import Foundation

/// CSV出力形式
enum ExportFormat: String, CaseIterable, Codable, Identifiable, Sendable {
    case freee = "freee"
    case yayoi = "弥生会計"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var fileNamePrefix: String {
        switch self {
        case .freee: return "freee_import"
        case .yayoi: return "yayoi_import"
        }
    }
}

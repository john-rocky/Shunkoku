import Foundation

/// 勘定科目 — 個人事業主（青色申告）でよく使う科目
enum AccountCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    // MARK: - 経費科目
    case travelAndTransportation = "旅費交通費"
    case communication = "通信費"
    case consumables = "消耗品費"
    case entertainment = "接待交際費"
    case rent = "地代家賃"
    case utilities = "水道光熱費"
    case advertising = "広告宣伝費"
    case outsourcing = "外注工賃"
    case welfare = "福利厚生費"
    case miscellaneousExpense = "雑費"
    case officeSupplies = "事務用品費"
    case repairs = "修繕費"
    case insurance = "保険料"
    case vehicleExpenses = "車両費"
    case booksAndSubscriptions = "新聞図書費"
    case meetingExpenses = "会議費"
    case training = "研修費"
    case membershipFees = "諸会費"
    case taxesAndDues = "租税公課"

    // MARK: - 収入科目
    case sales = "売上高"
    case miscellaneousIncome = "雑収入"

    var id: String { rawValue }

    var displayName: String { rawValue }

    /// 収入科目かどうか
    var isIncome: Bool {
        switch self {
        case .sales, .miscellaneousIncome:
            return true
        default:
            return false
        }
    }

    /// 弥生会計向けの貸方勘定科目
    var defaultCounterAccount: String {
        if isIncome {
            return "普通預金"
        }
        return "事業主借"
    }

    /// freee向けの税区分デフォルト
    var defaultTaxLabel: String {
        switch self {
        case .taxesAndDues:
            return "対象外"
        case .insurance:
            return "対象外"
        default:
            return isIncome ? "課税売上10%" : "課対仕入10%"
        }
    }

    /// 経費科目のみ
    static var expenseCategories: [AccountCategory] {
        allCases.filter { !$0.isIncome }
    }

    /// 収入科目のみ
    static var incomeCategories: [AccountCategory] {
        allCases.filter { $0.isIncome }
    }
}

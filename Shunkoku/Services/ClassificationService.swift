import Foundation
import FoundationModels
import SwiftData

/// 取引の勘定科目を分類するサービス
/// Foundation Models → キーワードベースのフォールバック
@MainActor
final class ClassificationService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Interface

    /// 単一の取引を分類
    func classify(_ request: TransactionClassificationRequest) async -> (category: AccountCategory, taxRate: TaxRate, reason: String) {
        // 1. CategoryMapping（ユーザー定義 + 学習済み）から検索
        if let mapping = findMapping(for: request.counterpartyName) {
            return (mapping.category, mapping.taxRate ?? .standard, "キーワードマッチ: \(mapping.keyword)")
        }

        // 2. Foundation Models で分類
        if let result = await classifyWithAI(request) {
            return result
        }

        // 3. キーワードベースのフォールバック
        return classifyWithKeywords(request)
    }

    /// 複数の取引を分類
    func classify(_ requests: [TransactionClassificationRequest]) async -> [(category: AccountCategory, taxRate: TaxRate, reason: String)] {
        var results: [(category: AccountCategory, taxRate: TaxRate, reason: String)] = []
        for request in requests {
            let result = await classify(request)
            results.append(result)
        }
        return results
    }

    /// ユーザーの修正を学習（CategoryMappingに保存）
    func learnFromCorrection(counterpartyName: String, category: AccountCategory, taxRate: TaxRate) {
        let keyword = counterpartyName.lowercased()

        // 既存のマッピングを検索
        let descriptor = FetchDescriptor<CategoryMapping>(
            predicate: #Predicate { $0.keyword == keyword }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.category = category
            existing.taxRate = taxRate
            existing.usageCount += 1
            existing.isUserDefined = true
        } else {
            let mapping = CategoryMapping(
                keyword: keyword,
                category: category,
                taxRate: taxRate,
                isUserDefined: true
            )
            modelContext.insert(mapping)
        }

        try? modelContext.save()
    }

    // MARK: - CategoryMapping Lookup

    private func findMapping(for counterpartyName: String) -> CategoryMapping? {
        let name = counterpartyName.lowercased()
        let descriptor = FetchDescriptor<CategoryMapping>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        guard let mappings = try? modelContext.fetch(descriptor) else { return nil }

        return mappings.first { name.contains($0.keyword) || $0.keyword.contains(name) }
    }

    // MARK: - Foundation Models Classification

    private func classifyWithAI(_ request: TransactionClassificationRequest) async -> (category: AccountCategory, taxRate: TaxRate, reason: String)? {
        do {
            let session = LanguageModelSession {
                """
                あなたは日本の個人事業主（青色申告）の経理アシスタントです。
                取引情報から、最も適切な勘定科目と消費税率を判定してください。

                【勘定科目の判定基準】
                - 旅費交通費: 電車・バス・タクシー・新幹線・飛行機・ICカードチャージ
                - 通信費: 携帯電話・インターネット・郵便・切手
                - 消耗品費: 10万円未満の備品・文具以外の消耗品
                - 接待交際費: 取引先との飲食・贈答品・慶弔費
                - 地代家賃: 事務所・駐車場の賃料
                - 水道光熱費: 電気・ガス・水道
                - 広告宣伝費: Web広告・チラシ・名刺
                - 外注工賃: 業務委託費・デザイン費・開発費
                - 会議費: 1人5,000円以下の飲食（打合せ目的）
                - 新聞図書費: 書籍・雑誌・電子書籍・サブスクリプション
                - 事務用品費: 文具・コピー用紙・プリンタインク
                - 車両費: ガソリン・駐車場・高速道路・車検
                - 研修費: セミナー・研修・資格取得費
                - 諸会費: 業界団体・商工会議所の年会費
                - 福利厚生費: 従業員向けの福利厚生
                - 保険料: 事業用保険
                - 修繕費: 修理・メンテナンス
                - 租税公課: 印紙税・自動車税・固定資産税
                - 雑費: 上記に該当しないもの

                【消費税率】
                - 10%: 標準税率（ほとんどの取引）
                - 8%: 軽減税率（飲食料品・新聞）
                - 非課税: 保険料・租税公課・一部の金融取引
                """
            }

            let prompt = "取引先名: \(request.counterpartyName), 金額: \(request.amount)円, ソース: \(request.sourceType), メモ: \(request.memo)"

            let response = try await session.respond(to: prompt, generating: TransactionClassification.self)

            let category = AccountCategory(rawValue: response.content.category) ?? .miscellaneousExpense
            let taxRate = TaxRate(rawValue: response.content.taxRate) ?? .standard

            return (category, taxRate, response.content.reason)
        } catch {
            return nil
        }
    }

    // MARK: - Keyword Fallback

    private func classifyWithKeywords(_ request: TransactionClassificationRequest) -> (category: AccountCategory, taxRate: TaxRate, reason: String) {
        let name = request.counterpartyName.lowercased()
        let allText = "\(name) \(request.memo.lowercased())"

        // 旅費交通費
        let transportKeywords = ["jr", "東日本", "西日本", "suica", "pasmo", "icoca", "タクシー", "交通", "鉄道", "バス", "航空", "ana", "jal", "新幹線"]
        if transportKeywords.contains(where: { allText.contains($0) }) {
            return (.travelAndTransportation, .standard, "キーワード: 交通関連")
        }

        // 通信費
        let commKeywords = ["docomo", "au", "softbank", "楽天モバイル", "ntt", "通信", "インターネット", "wi-fi", "プロバイダ"]
        if commKeywords.contains(where: { allText.contains($0) }) {
            return (.communication, .standard, "キーワード: 通信関連")
        }

        // 水道光熱費
        let utilityKeywords = ["電力", "ガス", "水道", "東京電力", "関西電力", "東京ガス", "大阪ガス"]
        if utilityKeywords.contains(where: { allText.contains($0) }) {
            return (.utilities, .standard, "キーワード: 光熱費関連")
        }

        // 地代家賃
        let rentKeywords = ["家賃", "賃料", "不動産", "管理費", "共益費"]
        if rentKeywords.contains(where: { allText.contains($0) }) {
            return (.rent, .exempt, "キーワード: 家賃関連")
        }

        // 会議費（カフェ系）
        let cafeKeywords = ["スターバックス", "starbucks", "タリーズ", "ドトール", "カフェ", "珈琲"]
        if cafeKeywords.contains(where: { allText.contains($0) }) {
            return (.meetingExpenses, .reduced, "キーワード: カフェ（会議費）")
        }

        // 新聞図書費
        let bookKeywords = ["amazon kindle", "書店", "本屋", "紀伊國屋", "丸善", "ジュンク堂", "books"]
        if bookKeywords.contains(where: { allText.contains($0) }) {
            return (.booksAndSubscriptions, .standard, "キーワード: 書籍関連")
        }

        // 事務用品費
        let officeKeywords = ["文具", "コクヨ", "ロフト", "ハンズ", "100均", "ダイソー", "セリア"]
        if officeKeywords.contains(where: { allText.contains($0) }) {
            return (.officeSupplies, .standard, "キーワード: 事務用品関連")
        }

        // 消耗品費（ECサイト）
        let ecKeywords = ["amazon", "アマゾン", "ヨドバシ", "ビックカメラ", "楽天市場"]
        if ecKeywords.contains(where: { allText.contains($0) }) {
            return (.consumables, .standard, "キーワード: EC購入（消耗品）")
        }

        // 接待交際費（飲食店）
        let diningKeywords = ["居酒屋", "レストラン", "焼肉", "寿司", "料理", "dining"]
        if diningKeywords.contains(where: { allText.contains($0) }) {
            return (.entertainment, .standard, "キーワード: 飲食店（交際費）")
        }

        // 車両費
        let vehicleKeywords = ["ガソリン", "eneos", "出光", "コスモ", "駐車", "高速", "etc"]
        if vehicleKeywords.contains(where: { allText.contains($0) }) {
            return (.vehicleExpenses, .standard, "キーワード: 車両関連")
        }

        // デフォルト
        return (.miscellaneousExpense, .standard, "分類不能のため雑費")
    }
}

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryMapping.keyword) private var mappings: [CategoryMapping]

    @State private var showAddMapping = false
    @State private var newKeyword = ""
    @State private var newCategory: AccountCategory = .miscellaneousExpense
    @State private var newTaxRate: TaxRate = .standard

    var body: some View {
        List {
            // アプリ情報
            Section("アプリ情報") {
                LabeledContent("アプリ名") { Text(Constants.App.name) }
                LabeledContent("バージョン") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }

            // カテゴリマッピング管理
            Section("カテゴリマッピング") {
                if mappings.isEmpty {
                    Text("マッピングなし")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(mappings) { mapping in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mapping.keyword)
                                    .font(.body)
                                HStack(spacing: 4) {
                                    if mapping.isUserDefined {
                                        Text("ユーザー定義")
                                    } else {
                                        Text("AI提案")
                                    }
                                    Text("・使用\(mapping.usageCount)回")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(mapping.category.displayName)
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1), in: Capsule())
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(mappings[index])
                        }
                        try? modelContext.save()
                    }
                }

                Button("マッピングを追加") {
                    showAddMapping = true
                }
            }

            // データ管理
            Section("データ管理") {
                Button("サンプルデータを生成", role: .none) {
                    generateSampleData()
                }
                Button("全データを削除", role: .destructive) {
                    deleteAllData()
                }
            }
        }
        .navigationTitle("設定")
        .alert("マッピングを追加", isPresented: $showAddMapping) {
            TextField("キーワード", text: $newKeyword)
            Button("追加") {
                guard !newKeyword.isEmpty else { return }
                let mapping = CategoryMapping(
                    keyword: newKeyword,
                    category: newCategory,
                    taxRate: newTaxRate,
                    isUserDefined: true
                )
                modelContext.insert(mapping)
                try? modelContext.save()
                newKeyword = ""
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    // MARK: - Sample Data

    private func generateSampleData() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()

        let samples: [(String, Int, AccountCategory, TaxRate)] = [
            ("JR東日本", 1320, .travelAndTransportation, .standard),
            ("スターバックス 渋谷店", 550, .meetingExpenses, .reduced),
            ("Amazon.co.jp", 3980, .consumables, .standard),
            ("NTTドコモ", 8800, .communication, .standard),
            ("東京電力", 12500, .utilities, .standard),
            ("紀伊國屋書店", 2200, .booksAndSubscriptions, .standard),
            ("居酒屋 和民", 15000, .entertainment, .standard),
            ("コクヨ オンライン", 1500, .officeSupplies, .standard),
        ]

        for (i, sample) in samples.enumerated() {
            let date = calendar.date(byAdding: .day, value: -i * 3, to: now) ?? now
            let tx = Transaction(
                date: date,
                amount: sample.1,
                counterpartyName: sample.0,
                category: sample.2,
                taxRate: sample.3,
                transactionType: .expense,
                sourceType: .creditCard,
                isConfirmed: i % 3 == 0
            )
            modelContext.insert(tx)
        }

        // 収入サンプル
        let income = Transaction(
            date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            amount: 500000,
            counterpartyName: "株式会社クライアント",
            category: .sales,
            taxRate: .standard,
            transactionType: .income,
            sourceType: .bankStatement,
            isConfirmed: true
        )
        modelContext.insert(income)

        try? modelContext.save()
    }

    private func deleteAllData() {
        try? modelContext.delete(model: Transaction.self)
        try? modelContext.delete(model: TransactionBatch.self)
        try? modelContext.delete(model: Counterparty.self)
        try? modelContext.delete(model: CategoryMapping.self)
        try? modelContext.save()
    }
}

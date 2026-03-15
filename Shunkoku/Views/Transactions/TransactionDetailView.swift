import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var transaction: Transaction
    @State private var isEditing = false

    var body: some View {
        Form {
            // 基本情報
            Section("取引情報") {
                LabeledContent("取引先") {
                    if isEditing {
                        TextField("取引先", text: $transaction.counterpartyName)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(transaction.counterpartyName)
                    }
                }

                LabeledContent("金額") {
                    if isEditing {
                        TextField("金額", value: $transaction.amount, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    } else {
                        Text(CurrencyFormatters.displayYen(transaction.amount))
                    }
                }

                if isEditing {
                    DatePicker("日付", selection: $transaction.date, displayedComponents: .date)
                } else {
                    LabeledContent("日付") {
                        Text(DateFormatters.displayFull.string(from: transaction.date))
                    }
                }
            }

            // 分類
            Section("分類") {
                if isEditing {
                    Picker("勘定科目", selection: Binding(
                        get: { transaction.category },
                        set: { transaction.category = $0 }
                    )) {
                        ForEach(AccountCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }

                    Picker("税率", selection: Binding(
                        get: { transaction.taxRate },
                        set: { transaction.taxRate = $0 }
                    )) {
                        ForEach(TaxRate.allCases) { rate in
                            Text(rate.displayName).tag(rate)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("区分", selection: Binding(
                        get: { transaction.transactionType },
                        set: { transaction.transactionType = $0 }
                    )) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    LabeledContent("勘定科目") { Text(transaction.category.displayName) }
                    LabeledContent("税率") { Text(transaction.taxRate.displayName) }
                    LabeledContent("区分") { Text(transaction.transactionType.displayName) }
                }
            }

            // メモ
            Section("メモ") {
                if isEditing {
                    TextField("メモ", text: $transaction.memo, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    Text(transaction.memo.isEmpty ? "なし" : transaction.memo)
                        .foregroundStyle(transaction.memo.isEmpty ? .secondary : .primary)
                }
            }

            // メタ情報
            Section("詳細") {
                LabeledContent("ソース") { Text(transaction.sourceType.displayName) }
                LabeledContent("確認状態") {
                    Button {
                        transaction.isConfirmed.toggle()
                        try? modelContext.save()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: transaction.isConfirmed ? "checkmark.circle.fill" : "circle")
                            Text(transaction.isConfirmed ? "確認済み" : "未確認")
                        }
                        .foregroundStyle(transaction.isConfirmed ? .green : .orange)
                    }
                }
                LabeledContent("登録日") {
                    Text(DateFormatters.displayFull.string(from: transaction.createdAt))
                }
            }
        }
        .navigationTitle("取引詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "完了" : "編集") {
                    if isEditing {
                        // 保存時にCategoryMapping学習
                        let ctx = modelContext
                        let name = transaction.counterpartyName
                        let cat = transaction.category
                        let rate = transaction.taxRate
                        Task {
                            let service = ClassificationService(modelContext: ctx)
                            await service.learnFromCorrection(
                                counterpartyName: name,
                                category: cat,
                                taxRate: rate
                            )
                        }
                        try? modelContext.save()
                    }
                    isEditing.toggle()
                }
            }
        }
    }
}

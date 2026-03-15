import SwiftUI

/// スキャン結果確認 & 編集画面
struct ScanResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ScanViewModel

    var body: some View {
        Group {
            if viewModel.isProcessing {
                processingView
            } else if viewModel.parsedTransactions.isEmpty {
                emptyResultView
            } else {
                resultsList
            }
        }
        .navigationTitle("スキャン結果")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    viewModel.saveTransactions(modelContext: modelContext)
                    dismiss()
                }
                .disabled(viewModel.parsedTransactions.isEmpty || viewModel.isProcessing)
            }
        }
        .alert("エラー", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.error ?? "不明なエラー")
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.processingProgress)
                .padding(.horizontal)
            Text(viewModel.processingStatus)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty Result

    private var emptyResultView: some View {
        ContentUnavailableView(
            "取引が検出されませんでした",
            systemImage: "doc.text.magnifyingglass",
            description: Text("画像の内容を確認して、もう一度お試しください")
        )
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            Section("検出された取引 (\(viewModel.parsedTransactions.count)件)") {
                ForEach($viewModel.parsedTransactions) { $transaction in
                    EditableTransactionRow(transaction: $transaction)
                }
                .onDelete { indexSet in
                    viewModel.parsedTransactions.remove(atOffsets: indexSet)
                }
            }
        }
    }
}

// MARK: - Editable Transaction Row

struct EditableTransactionRow: View {
    @Binding var transaction: ScanViewModel.EditableTransaction

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // メイン行
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.counterpartyName)
                        .font(.body.bold())
                    Text(DateFormatters.displayShort.string(from: transaction.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(CurrencyFormatters.displayYen(transaction.amount))
                    .font(.body.bold().monospacedDigit())
            }
            .contentShape(Rectangle())
            .onTapGesture { isExpanded.toggle() }

            // 分類タグ
            HStack(spacing: 8) {
                Text(transaction.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())

                Text(transaction.taxRate.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.1), in: Capsule())

                if !transaction.classificationReason.isEmpty {
                    Text(transaction.classificationReason)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // 展開時: 編集フォーム
            if isExpanded {
                editForm
            }
        }
        .padding(.vertical, 4)
    }

    private var editForm: some View {
        VStack(spacing: 12) {
            Divider()

            TextField("取引先名", text: $transaction.counterpartyName)
                .textFieldStyle(.roundedBorder)

            HStack {
                DatePicker("日付", selection: $transaction.date, displayedComponents: .date)
                    .labelsHidden()

                TextField("金額", value: $transaction.amount, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 120)
            }

            Picker("勘定科目", selection: $transaction.category) {
                ForEach(AccountCategory.allCases) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }

            HStack {
                Picker("税率", selection: $transaction.taxRate) {
                    ForEach(TaxRate.allCases) { rate in
                        Text(rate.displayName).tag(rate)
                    }
                }
                .pickerStyle(.segmented)
            }

            TextField("メモ", text: $transaction.memo)
                .textFieldStyle(.roundedBorder)
        }
    }
}

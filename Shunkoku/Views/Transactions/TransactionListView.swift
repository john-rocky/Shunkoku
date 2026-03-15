import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionListViewModel()
    @Query private var allTransactions: [Transaction]

    var body: some View {
        VStack(spacing: 0) {
            // 支出/収入切替
            Picker("区分", selection: $viewModel.selectedType) {
                ForEach(TransactionType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // フィルターバー
            filterBar

            // 取引リスト
            TransactionQueryListView(
                viewModel: viewModel,
                modelContext: modelContext
            )
        }
        .navigationTitle("取引一覧")
        .searchable(text: $viewModel.searchText, prompt: "取引先名・メモで検索")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    IncomeListView()
                } label: {
                    Label("収入管理", systemImage: "yensign.circle")
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 月フィルタ
                Menu {
                    Button("すべて") { viewModel.selectedMonth = nil }
                    ForEach(TransactionListViewModel.availableMonths(from: allTransactions), id: \.self) { month in
                        Button(DateFormatters.displayMonth.string(from: month)) {
                            viewModel.selectedMonth = month
                        }
                    }
                } label: {
                    FilterChip(
                        label: viewModel.selectedMonth.map { DateFormatters.displayMonth.string(from: $0) } ?? "月",
                        isActive: viewModel.selectedMonth != nil
                    )
                }

                // 科目フィルタ
                Menu {
                    Button("すべて") { viewModel.selectedCategory = nil }
                    ForEach(AccountCategory.allCases) { cat in
                        Button(cat.displayName) { viewModel.selectedCategory = cat }
                    }
                } label: {
                    FilterChip(
                        label: viewModel.selectedCategory?.displayName ?? "科目",
                        isActive: viewModel.selectedCategory != nil
                    )
                }

                // ソースフィルタ
                Menu {
                    Button("すべて") { viewModel.selectedSourceType = nil }
                    ForEach(SourceType.allCases) { src in
                        Button(src.displayName) { viewModel.selectedSourceType = src }
                    }
                } label: {
                    FilterChip(
                        label: viewModel.selectedSourceType?.displayName ?? "ソース",
                        isActive: viewModel.selectedSourceType != nil
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1), in: Capsule())
            .foregroundStyle(isActive ? Color.accentColor : .secondary)
    }
}

// MARK: - Query List (動的Predicate対応)

struct TransactionQueryListView: View {
    let viewModel: TransactionListViewModel
    let modelContext: ModelContext

    @Query private var transactions: [Transaction]

    init(viewModel: TransactionListViewModel, modelContext: ModelContext) {
        self.viewModel = viewModel
        self.modelContext = modelContext
        _transactions = Query(viewModel.fetchDescriptor)
    }

    var body: some View {
        List {
            if transactions.isEmpty {
                ContentUnavailableView(
                    "取引がありません",
                    systemImage: "tray",
                    description: Text("スキャンタブから経費を登録しましょう")
                )
            } else {
                ForEach(transactions) { transaction in
                    NavigationLink {
                        TransactionDetailView(transaction: transaction)
                    } label: {
                        TransactionRow(transaction: transaction)
                    }
                }
                .onDelete { indexSet in
                    let toDelete = indexSet.map { transactions[$0] }
                    viewModel.deleteTransactions(toDelete, modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if !transaction.isConfirmed {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                    }
                    Text(transaction.counterpartyName)
                        .font(.body)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text(DateFormatters.displayShort.string(from: transaction.date))
                    Text(transaction.category.displayName)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(CurrencyFormatters.displayYen(transaction.amount))
                .font(.body.monospacedDigit())
                .foregroundStyle(transaction.transactionType == .income ? .green : .primary)
        }
        .padding(.vertical, 2)
    }
}

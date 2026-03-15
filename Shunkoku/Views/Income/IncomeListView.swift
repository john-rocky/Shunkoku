import SwiftUI
import SwiftData

struct IncomeListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = IncomeViewModel()

    var body: some View {
        let summaries = viewModel.fetchCounterpartySummaries(modelContext: modelContext)

        List {
            if summaries.isEmpty {
                ContentUnavailableView(
                    "収入データがありません",
                    systemImage: "yensign.circle",
                    description: Text("スキャンから収入を登録するか、\n取引一覧で区分を「収入」に変更してください")
                )
            } else {
                // 合計
                Section {
                    HStack {
                        Text("合計")
                            .font(.headline)
                        Spacer()
                        Text(CurrencyFormatters.displayYen(summaries.reduce(0) { $0 + $1.totalAmount }))
                            .font(.headline.monospacedDigit())
                    }
                }

                // 取引先別
                Section("取引先別") {
                    ForEach(summaries) { summary in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.name)
                                    .font(.body)
                                Text("\(summary.transactionCount)件")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(CurrencyFormatters.displayYen(summary.totalAmount))
                                .font(.body.monospacedDigit())
                        }
                    }
                }
            }
        }
        .navigationTitle("収入管理")
        .searchable(text: $viewModel.searchText, prompt: "取引先名で検索")
    }
}

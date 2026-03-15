import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 月選択ヘッダー
                monthSelector

                // 月次サマリーカード
                summaryCards

                // 未確認件数
                if viewModel.unconfirmedCount > 0 {
                    unconfirmedBanner
                }

                // 科目別内訳
                if !viewModel.categoryBreakdown.isEmpty {
                    categoryBreakdownSection
                }
            }
            .padding()
        }
        .navigationTitle("ダッシュボード")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .onAppear {
            viewModel.refresh(modelContext: modelContext)
        }
        .onChange(of: viewModel.selectedMonth) {
            viewModel.refresh(modelContext: modelContext)
        }
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(DateFormatters.displayMonth.string(from: viewModel.selectedMonth))
                .font(.title2.bold())

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "支出",
                amount: viewModel.monthlyExpense,
                color: .red
            )
            SummaryCard(
                title: "収入",
                amount: viewModel.monthlyIncome,
                color: .green
            )
        }
    }

    // MARK: - Unconfirmed Banner

    private var unconfirmedBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
            Text("未確認の取引が\(viewModel.unconfirmedCount)件あります")
                .font(.subheadline)
            Spacer()
            NavigationLink("確認する") {
                TransactionListView()
            }
            .font(.subheadline.bold())
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("科目別内訳")
                .font(.headline)

            ForEach(viewModel.categoryBreakdown, id: \.category) { item in
                HStack {
                    Text(item.category.displayName)
                        .font(.subheadline)
                    Spacer()
                    Text(CurrencyFormatters.displayYen(item.amount))
                        .font(.subheadline.monospacedDigit())
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let amount: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(CurrencyFormatters.displayYen(amount))
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

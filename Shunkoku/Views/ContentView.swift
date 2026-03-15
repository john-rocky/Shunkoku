import SwiftUI

/// メインのTabView（4タブ）
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("ダッシュボード", systemImage: "chart.pie", value: 0) {
                NavigationStack {
                    DashboardView()
                }
            }

            Tab("スキャン", systemImage: "camera.viewfinder", value: 1) {
                NavigationStack {
                    ScanEntryView()
                }
            }

            Tab("取引一覧", systemImage: "list.bullet.rectangle", value: 2) {
                NavigationStack {
                    TransactionListView()
                }
            }

            Tab("エクスポート", systemImage: "square.and.arrow.up", value: 3) {
                NavigationStack {
                    ExportView()
                }
            }
        }
    }
}

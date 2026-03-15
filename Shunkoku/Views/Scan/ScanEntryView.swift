import SwiftUI
import PhotosUI

/// スキャンフロー: ソース選択 → 画像選択 → 処理 → 結果確認
struct ScanEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ScanViewModel()
    @State private var showPhotoPicker = false
    @State private var showResults = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // アイコン
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            Text("スクリーンショットをスキャン")
                .font(.title2.bold())

            Text("クレジットカード明細・銀行明細・レシートの\nスクリーンショットから経費を自動登録します")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // ソース種別選択
            VStack(alignment: .leading, spacing: 8) {
                Text("ソース種別")
                    .font(.subheadline.bold())
                Picker("ソース種別", selection: $viewModel.selectedSourceType) {
                    ForEach(SourceType.allCases) { type in
                        Label(type.displayName, systemImage: type.systemImage)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            // スキャンボタン
            Button {
                showPhotoPicker = true
            } label: {
                Label("写真を選択", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("スキャン")
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $viewModel.selectedPhotos,
            maxSelectionCount: 10,
            matching: .screenshots
        )
        .onChange(of: viewModel.selectedPhotos) {
            guard !viewModel.selectedPhotos.isEmpty else { return }
            Task {
                await viewModel.loadImages()
                if !viewModel.loadedImages.isEmpty {
                    showResults = true
                    await viewModel.processImages(modelContext: modelContext)
                }
            }
        }
        .sheet(isPresented: $showResults) {
            viewModel.reset()
        } content: {
            NavigationStack {
                ScanResultsView(viewModel: viewModel)
            }
        }
    }
}

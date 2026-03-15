import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ExportViewModel()
    @State private var showShareSheet = false

    var body: some View {
        Form {
            // 出力形式
            Section("出力形式") {
                Picker("形式", selection: $viewModel.selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                Picker("文字コード", selection: $viewModel.encoding) {
                    Text(CSVExportService.CSVEncoding.shiftJIS.displayName)
                        .tag(CSVExportService.CSVEncoding.shiftJIS)
                    Text(CSVExportService.CSVEncoding.utf8BOM.displayName)
                        .tag(CSVExportService.CSVEncoding.utf8BOM)
                }
            }

            // 期間
            Section("対象期間") {
                DatePicker("開始日", selection: $viewModel.startDate, displayedComponents: .date)
                DatePicker("終了日", selection: $viewModel.endDate, displayedComponents: .date)
                Toggle("未確認の取引も含める", isOn: $viewModel.includeUnconfirmed)
            }

            // プレビュー
            Section("プレビュー") {
                Button("プレビューを更新") {
                    viewModel.generatePreview(modelContext: modelContext)
                }

                if viewModel.totalCount > 0 {
                    Text("\(viewModel.totalCount)件の取引")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.preview.isEmpty {
                    ScrollView(.horizontal) {
                        Text(viewModel.preview)
                            .font(.system(.caption2, design: .monospaced))
                            .padding(8)
                    }
                    .frame(maxHeight: 200)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            // エクスポートボタン
            Section {
                Button {
                    viewModel.generateCSV(modelContext: modelContext)
                    showShareSheet = true
                } label: {
                    Label("CSVをエクスポート", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.totalCount == 0)
            }
        }
        .navigationTitle("エクスポート")
        .onAppear {
            viewModel.generatePreview(modelContext: modelContext)
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = viewModel.exportData {
                ShareSheetView(data: data, fileName: viewModel.fileName)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let data: Data
    let fileName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

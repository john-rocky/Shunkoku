import SwiftUI
import SwiftData

@main
struct ShunkokuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Transaction.self,
            TransactionBatch.self,
            Counterparty.self,
            CategoryMapping.self,
        ])
    }
}

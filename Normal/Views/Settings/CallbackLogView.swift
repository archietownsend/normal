import SwiftUI
import UIKit

struct CallbackLogView: View {
    @State private var lines: [String] = []

    var body: some View {
        ScrollView {
            Text(lines.reversed().joined(separator: "\n"))
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("Callback Log (\(lines.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Copy") {
                    UIPasteboard.general.string = lines.joined(separator: "\n")
                }
                Button("Clear", role: .destructive) {
                    CallbackLog.clear()
                    lines = []
                }
            }
        }
        .refreshable { lines = CallbackLog.read() }
        .onAppear { lines = CallbackLog.read() }
    }
}

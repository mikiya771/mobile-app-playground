import SwiftUI

// Step 2: @State / @Binding / @Observable の使い分けデモ
// このファイルは学習用。Step 4 以降で実際の ViewModel に置き換わる。

// ─── @Observable ViewModel（Riverpod Notifier 相当） ───────────────────────
@Observable
final class CounterViewModel {
    var count = 0

    func increment() { count += 1 }
    func reset() { count = 0 }
}

// ─── 子 View：@Binding で親の状態を受け取る ────────────────────────────────
struct IncrementButton: View {
    @Binding var count: Int          // 親が所有、子が読み書き

    var body: some View {
        Button("タップ: \(count)") {
            count += 1
        }
        .buttonStyle(.borderedProminent)
    }
}

// ─── Screen：@State で ViewModel を保持（ref.watch 相当） ─────────────────
struct StatePlaygroundView: View {
    @State private var viewModel = CounterViewModel()   // Screen 層が所有
    @State private var localCount = 0                   // ローカル状態

    var body: some View {
        VStack(spacing: 20) {
            Text("@Observable ViewModel")
                .font(.headline)
            Text("\(viewModel.count)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            HStack(spacing: 12) {
                Button("＋", action: viewModel.increment)
                    .buttonStyle(.borderedProminent)
                Button("リセット", action: viewModel.reset)
                    .buttonStyle(.bordered)
            }

            Divider()

            Text("@Binding（子 View 経由）")
                .font(.headline)
            IncrementButton(count: $localCount)
        }
        .padding()
        .navigationTitle("Step 2: 状態管理")
    }
}

#Preview {
    NavigationStack {
        StatePlaygroundView()
    }
}

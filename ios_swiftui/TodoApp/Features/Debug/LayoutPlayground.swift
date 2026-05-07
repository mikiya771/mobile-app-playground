import SwiftUI

// Step 3: VStack / HStack / ZStack / Modifier のレイアウト実習
// Flutter の Column / Row / Stack + BoxDecoration に対応

// ─── 優先度バッジ（ZStack でオーバーレイ実習） ────────────────────────────
struct PriorityDot: View {
    enum Priority { case low, medium, high
        var color: Color {
            switch self {
            case .low: .green
            case .medium: .orange
            case .high: .red
            }
        }
        var label: String {
            switch self {
            case .low: "低"
            case .medium: "中"
            case .high: "高"
            }
        }
    }

    let priority: Priority

    var body: some View {
        Text(priority.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color)
            .clipShape(Capsule())
    }
}

// ─── TodoCard のレイアウト実習 ────────────────────────────────────────────
struct LayoutTodoCard: View {
    let title: String
    let subtitle: String
    let priority: PriorityDot.Priority
    let isCompleted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCompleted ? Color.accentColor : Color.secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()  // Flutter: MainAxisAlignment.spaceBetween 相当

            PriorityDot(priority: priority)
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// ─── ZStack オーバーレイ実習 ──────────────────────────────────────────────
struct BadgeOverlayCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .frame(height: 80)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            Text("サンプルカード")
                .padding()
            PriorityDot(priority: .high)
                .offset(x: 8, y: -8)
        }
    }
}

// ─── Step 3 まとめ画面 ────────────────────────────────────────────────────
struct LayoutPlaygroundView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    Text("HStack + Spacer")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    LayoutTodoCard(title: "買い物をする", subtitle: "説明テキスト", priority: .high, isCompleted: false)
                    LayoutTodoCard(title: "完了済みタスク", subtitle: "取り消し線あり", priority: .low, isCompleted: true)
                }

                Group {
                    Text("ZStack オーバーレイ")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    BadgeOverlayCard()
                }

                Group {
                    Text("PriorityDot 全種類")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 8) {
                        ForEach([PriorityDot.Priority.low, .medium, .high], id: \.label) {
                            PriorityDot(priority: $0)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Step 3: レイアウト")
    }
}

#Preview {
    NavigationStack {
        LayoutPlaygroundView()
    }
}

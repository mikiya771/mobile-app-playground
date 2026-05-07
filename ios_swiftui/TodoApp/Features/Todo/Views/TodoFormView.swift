import SwiftUI

struct TodoFormView: View {
    let editingTodo: Todo?
    let onSave: (Todo) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var priority: TodoPriority = .medium

    var isNew: Bool { editingTodo == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("必須", text: $title)
                }
                Section("説明") {
                    TextField("任意", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("優先度") {
                    Picker("優先度", selection: $priority) {
                        ForEach(TodoPriority.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isNew ? "新規作成" : "編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let todo = Todo(
                            id: editingTodo?.id ?? UUID().uuidString,
                            title: title,
                            description: description,
                            isCompleted: editingTodo?.isCompleted ?? false,
                            priority: priority,
                            createdAt: editingTodo?.createdAt ?? .now
                        )
                        onSave(todo)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let todo = editingTodo {
                title = todo.title
                description = todo.description
                priority = todo.priority
            }
        }
    }
}

#Preview {
    TodoFormView(editingTodo: nil, onSave: { _ in })
}

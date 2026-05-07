import SwiftUI

// Flutter の FilterTabBar ウィジェットに相当
struct FilterTabBar: View {
    @Binding var selection: TodoFilter

    var body: some View {
        Picker("フィルター", selection: $selection) {
            ForEach(TodoFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

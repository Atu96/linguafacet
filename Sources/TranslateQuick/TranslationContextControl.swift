import SwiftUI

struct TranslationContextControl: View {
    @Binding var context: String
    @Binding var protectedTermsText: String
    @State private var isPresented = false

    private var requestContext: TranslationRequestContext {
        TranslationRequestContext(
            taskContext: context,
            protectedTermsText: protectedTermsText
        )
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label(
                requestContext.isEmpty ? "Ngữ cảnh" : "Ngữ cảnh · Đang dùng",
                systemImage: requestContext.isEmpty ? "scope" : "checkmark.circle.fill"
            )
            .lineLimit(1)
        }
        .buttonStyle(.glass)
        .frame(height: TQLayout.controlTarget)
        .help("Thêm ngữ cảnh và thuật ngữ cần giữ nguyên")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ngữ cảnh & thuật ngữ")
                            .font(.headline)
                        Text("Giúp xử lý từ đa nghĩa mà không thêm một lượt gọi AI.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Xong") { isPresented = false }
                        .keyboardShortcut(.cancelAction)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ngữ cảnh của nội dung")
                        .font(.subheadline.weight(.semibold))
                    TextField(
                        "Ví dụ: email trao đổi hợp đồng phần mềm",
                        text: $context,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .accessibilityLabel("Ngữ cảnh của nội dung")
                    Text("Chỉ dùng để gỡ nghĩa mơ hồ; AI không được đưa dữ kiện từ đây vào bản dịch.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Thuật ngữ giữ nguyên")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(requestContext.protectedTerms.count)/50")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                    TextEditor(text: $protectedTermsText)
                        .font(.system(.body, design: .rounded))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(height: 96)
                        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
                        .accessibilityLabel("Thuật ngữ cần giữ nguyên")
                    Text("Mỗi dòng một mục; cũng có thể ngăn cách bằng dấu phẩy hoặc chấm phẩy.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                if !context.isEmpty || !protectedTermsText.isEmpty {
                    HStack {
                        Spacer()
                        Button("Xóa nội dung hướng dẫn") {
                            context = ""
                            protectedTermsText = ""
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .padding(TQLayout.cardRadius)
            .frame(width: 390)
        }
    }
}

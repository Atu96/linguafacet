import AppKit
import SwiftUI

struct FocusedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var focusOnAppear = false
    var accessibilityLabel: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, focusOnAppear: focusOnAppear)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.verticalScrollElasticity = .automatic

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 8, height: 10)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let systemFont = NSFont.systemFont(ofSize: 16)
        let roundedDescriptor = systemFont.fontDescriptor.withDesign(.rounded) ?? systemFont.fontDescriptor
        textView.font = NSFont(descriptor: roundedDescriptor, size: 16)
        textView.textColor = .labelColor
        textView.insertionPointColor = .textColor
        textView.setAccessibilityLabel(accessibilityLabel)
        textView.setAccessibilityHelp("Có thể dùng các lệnh sửa chuẩn của macOS như Sao chép, Dán và Chọn tất cả.")
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        scrollView.documentView = textView
        context.coordinator.textView = textView
        let coordinator = context.coordinator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            coordinator.requestFocusIfNeeded()
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selection = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(NSRange(
                location: min(selection.location, (text as NSString).length),
                length: 0
            ))
        }
        textView.insertionPointColor = .textColor
        textView.setAccessibilityLabel(accessibilityLabel)
        context.coordinator.requestFocusIfNeeded()
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        private let focusOnAppear: Bool
        private var didRequestFocus = false
        weak var textView: NSTextView?

        init(text: Binding<String>, focusOnAppear: Bool) {
            _text = text
            self.focusOnAppear = focusOnAppear
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }

        func requestFocusIfNeeded() {
            guard focusOnAppear, !didRequestFocus, let textView, let window = textView.window else { return }
            didRequestFocus = true
            DispatchQueue.main.async {
                window.makeFirstResponder(textView)
                textView.setSelectedRange(NSRange(location: 0, length: 0))
            }
        }
    }
}

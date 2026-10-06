import AppKit
import ApplicationServices

@MainActor
final class SelectionController: ObservableObject {
    @Published private(set) var accessibilityGranted = AXIsProcessTrusted()

    enum SelectionError: LocalizedError {
        case accessibility
        case noSelection

        var errorDescription: String? {
            switch self {
            case .accessibility:
                "Cần bật quyền Accessibility cho LinguaFacet trong System Settings → Privacy & Security."
            case .noSelection:
                "Không thấy văn bản được chọn. Hãy bôi đen chữ rồi nhấn lại ⌘⇧T."
            }
        }
    }

    @discardableResult
    func refreshAccessibilityStatus() -> Bool {
        accessibilityGranted = AXIsProcessTrusted()
        return accessibilityGranted
    }

    func requestAccessibilityFromUser() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshAccessibilityStatus()
        }
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func copySelection() async throws -> String {
        guard refreshAccessibilityStatus() else { throw SelectionError.accessibility }

        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard: pasteboard)
        defer { snapshot.restore(to: pasteboard) }
        let oldChangeCount = pasteboard.changeCount
        postShortcut(keyCode: 8, flags: .maskCommand) // C
        try await Task.sleep(for: .milliseconds(180))

        guard pasteboard.changeCount != oldChangeCount,
              let text = pasteboard.string(forType: .string)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw SelectionError.noSelection
        }
        return text
    }

    func paste(_ text: String) async {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard: pasteboard)
        defer { snapshot.restore(to: pasteboard) }
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        try? await Task.sleep(for: .milliseconds(70))
        postShortcut(keyCode: 9, flags: .maskCommand) // V
        try? await Task.sleep(for: .milliseconds(180))
    }

    private func postShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

private struct PasteboardSnapshot {
    private let items: [NSPasteboardItem]

    init(pasteboard: NSPasteboard) {
        items = (pasteboard.pasteboardItems ?? []).map { source in
            let copy = NSPasteboardItem()
            for type in source.types {
                if let data = source.data(forType: type) {
                    copy.setData(data, forType: type)
                } else if let value = source.string(forType: type) {
                    copy.setString(value, forType: type)
                }
            }
            return copy
        }
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        guard !items.isEmpty else { return }
        pasteboard.writeObjects(items)
    }
}

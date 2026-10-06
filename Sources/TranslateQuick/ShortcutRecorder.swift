import AppKit
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    let label: String
    @Binding var shortcut: GlobalShortcut

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.controlLabel = label
        view.shortcut = shortcut
        view.onChange = { shortcut = $0 }
        return view
    }

    func updateNSView(_ view: ShortcutRecorderNSView, context: Context) {
        view.controlLabel = label
        if !view.isRecording { view.shortcut = shortcut }
    }
}

final class ShortcutRecorderNSView: NSView {
    var shortcut: GlobalShortcut = .openWindow {
        didSet {
            needsDisplay = true
            setAccessibilityValue(shortcut.displayName)
        }
    }
    var controlLabel = "Ghi phím tắt" {
        didSet { setAccessibilityLabel(controlLabel) }
    }
    var onChange: ((GlobalShortcut) -> Void)?
    private(set) var isRecording = false

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 142, height: 32) }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        focusRingType = .default
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(controlLabel)
        setAccessibilityHelp("Nhấn để ghi tổ hợp phím mới. Nhấn Escape để hủy.")
        setAccessibilityValue(shortcut.displayName)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        focusRingType = .default
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(controlLabel)
        setAccessibilityHelp("Nhấn để ghi tổ hợp phím mới. Nhấn Escape để hủy.")
        setAccessibilityValue(shortcut.displayName)
    }

    override func mouseDown(with event: NSEvent) {
        beginRecording()
    }

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { needsDisplay = true }
        return accepted
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        if !isRecording {
            if event.keyCode == 36 || event.keyCode == 49 {
                beginRecording()
            } else {
                super.keyDown(with: event)
            }
            return
        }
        if event.keyCode == 53 {
            isRecording = false
            window?.makeFirstResponder(nil)
            needsDisplay = true
            return
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= 0x0100 }
        if flags.contains(.shift) { modifiers |= 0x0200 }
        if flags.contains(.option) { modifiers |= 0x0800 }
        if flags.contains(.control) { modifiers |= 0x1000 }

        guard modifiers & (0x0100 | 0x0800 | 0x1000) != 0 else {
            NSSound.beep()
            return
        }

        let value = GlobalShortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        shortcut = value
        onChange?(value)
        isRecording = false
        window?.makeFirstResponder(nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bounds = self.bounds.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 9, yRadius: 9)
        (isRecording ? NSColor.controlAccentColor.withAlphaComponent(0.14) : NSColor.controlBackgroundColor.withAlphaComponent(0.72)).setFill()
        path.fill()
        (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = isRecording ? 1.5 : 1
        path.stroke()

        if window?.firstResponder === self {
            NSFocusRingPlacement.only.set()
            path.fill()
        }

        let value = isRecording ? "Nhấn tổ hợp phím…" : shortcut.displayName
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: isRecording ? 12 : 14, weight: .semibold),
            .foregroundColor: isRecording ? NSColor.controlAccentColor : NSColor.labelColor,
            .paragraphStyle: paragraph
        ]
        let textRect = NSRect(x: 5, y: (bounds.height - 17) / 2, width: bounds.width - 10, height: 18)
        value.draw(in: textRect, withAttributes: attributes)
    }

    override func accessibilityPerformPress() -> Bool {
        beginRecording()
        return true
    }

    private func beginRecording() {
        window?.makeFirstResponder(self)
        isRecording = true
        setAccessibilityValue("Đang ghi. (shortcut.displayName)")
        needsDisplay = true
    }
}

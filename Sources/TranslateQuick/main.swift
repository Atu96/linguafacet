import AppKit
import Carbon
import SwiftUI

private final class EscapeClosingWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }
}

private final class EscapeHidingPanel: NSPanel {
    override func cancelOperation(_ sender: Any?) {
        orderOut(sender)
    }
}

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let settings = SettingsStore()
    private lazy var model = AppModel(settings: settings)
    private lazy var styleModel = StyleTranslationModel(settings: settings)
    private let selection = SelectionController()

    private var hotKeys: HotKeyManager!
    private var statusItem: NSStatusItem!
    private var mainWindow: NSWindow!
    private var quickPanel: NSPanel!
    private var settingsWindow: NSWindow!
    private var quitAlert: NSAlert?
    private var quitEscapeMonitor: Any?
    private var isShowingQuitConfirmation = false

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        createWindows()
        createApplicationMenu()
        createMenuBar()
        registerHotKeys()
        connectActions()
        settings.applyTheme()

        if settings.selectionTranslationEnabled && !selection.refreshAccessibilityStatus() {
            model.status = L10n.string("Cần quyền Accessibility để dùng dịch vùng chọn")
        }
        showMainWindow(module: .quickTranslate)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func createApplicationMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu(title: "LinguaFacet")
        appItem.submenu = appMenu
        let settingsItem = NSMenuItem(title: L10n.string("Cài đặt") + "…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: L10n.string("Thoát LinguaFacet"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: L10n.string("Sửa"))
        editItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: L10n.string("Hoàn tác"), action: Selector(("undo:")), keyEquivalent: "z"))
        let redo = NSMenuItem(title: L10n.string("Làm lại"), action: Selector(("redo:")), keyEquivalent: "Z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redo)
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: L10n.string("Cắt"), action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: L10n.string("Sao chép"), action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: L10n.string("Dán"), action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: L10n.string("Chọn tất cả"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))

        NSApp.mainMenu = mainMenu
    }

    private func createWindows() {
        mainWindow = EscapeClosingWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        mainWindow.title = "LinguaFacet"
        mainWindow.titleVisibility = .hidden
        mainWindow.titlebarAppearsTransparent = true
        mainWindow.titlebarSeparatorStyle = .none
        mainWindow.isMovableByWindowBackground = true
        mainWindow.isReleasedWhenClosed = false
        mainWindow.delegate = self
        mainWindow.contentView = NSHostingView(rootView: AppRootView(model: model, styleModel: styleModel, settings: settings))
        configureMainWindowSizeLimits()
        mainWindow.center()

        quickPanel = EscapeHidingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 470, height: 330),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        quickPanel.level = .floating
        quickPanel.isFloatingPanel = true
        quickPanel.hidesOnDeactivate = false
        quickPanel.isOpaque = false
        quickPanel.backgroundColor = .clear
        quickPanel.hasShadow = true
        quickPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        quickPanel.contentView = NSHostingView(
            rootView: QuickPanelView(model: model, settings: settings)
                .environment(\.locale, Locale(identifier: settings.interfaceLanguage.rawValue))
        )

        settingsWindow = EscapeClosingWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 620),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = L10n.string("Cài đặt") + " LinguaFacet"
        settingsWindow.minSize = NSSize(width: 740, height: 580)
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.center()
        settingsWindow.contentView = NSHostingView(rootView: SettingsView(settings: settings, accessibility: selection))

        applyAlwaysOnTop(settings.alwaysOnTop)
    }

    private func configureMainWindowSizeLimits() {
        let minimumFrameSize = NSSize(
            width: TQLayout.mainWindowMinWidth,
            height: TQLayout.mainWindowMinHeight
        )
        let minimumContentRect = mainWindow.contentRect(
            forFrameRect: NSRect(origin: .zero, size: minimumFrameSize)
        )
        mainWindow.contentMinSize = minimumContentRect.size
        mainWindow.minSize = minimumFrameSize
        mainWindow.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: maximumMainWindowHeight(for: mainWindow)
        )
    }

    private func maximumMainWindowHeight(for window: NSWindow) -> CGFloat {
        let availableHeight = (window.screen ?? NSScreen.main)?.visibleFrame.height
            ?? TQLayout.mainWindowFallbackMaxHeight
        return max(
            TQLayout.mainWindowMinHeight,
            availableHeight - TQLayout.mainWindowScreenMargin
        )
    }

    private func connectActions() {
        model.onQuickResult = { [weak self] in self?.showQuickPanel() }
        model.onReplaceResult = { [weak self] text in
            guard let self else { return }
            Task {
                await self.selection.paste(text)
                self.quickPanel.orderOut(nil)
            }
        }
        model.onQuickCopy = { [weak self] in self?.quickPanel.orderOut(nil) }
        model.onRequestMainWindow = { [weak self] in
            self?.quickPanel.orderOut(nil)
            self?.showMainWindow(module: .quickTranslate)
        }
        model.onRequestSettings = { [weak self] in self?.showSettings() }
        model.onRequestGroqKeyOnboarding = { [weak self] in
            self?.showGroqKeyOnboardingIfNeeded(module: .quickTranslate) ?? false
        }
        model.onPreferredWindowHeight = { [weak self] height in self?.resizeMainWindow(to: height) }
        styleModel.onPreferredWindowHeight = { [weak self] height in self?.resizeMainWindow(to: height) }
        styleModel.onRequestStyleSettings = { [weak self] in
            self?.settings.selectedSettingsTab = .styles
            self?.showSettings()
        }
        styleModel.onRequestGroqKeyOnboarding = { [weak self] in
            self?.showGroqKeyOnboardingIfNeeded(module: .writingStyle) ?? false
        }
        styleModel.onPresetSelectionChanged = { [weak self] in self?.createMenuBar() }
        settings.onAlwaysOnTopChanged = { [weak self] enabled in self?.applyAlwaysOnTop(enabled) }
        settings.onShortcutsChanged = { [weak self] in
            self?.registerHotKeys()
            self?.createMenuBar()
        }
        settings.onMenuConfigurationChanged = { [weak self] in self?.createMenuBar() }
        settings.onInterfaceLanguageChanged = { [weak self] in
            self?.createApplicationMenu()
            self?.createMenuBar()
            self?.settingsWindow.title = L10n.string("Cài đặt") + " LinguaFacet"
        }
    }

    private func registerHotKeys() {
        if hotKeys == nil { hotKeys = HotKeyManager() } else { hotKeys.unregisterAll() }
        let openOK = hotKeys.register(id: 1, shortcut: settings.openShortcut) { [weak self] in
            self?.showMainWindow(module: .quickTranslate)
        }
        let quickOK = !settings.selectionTranslationEnabled || hotKeys.register(id: 2, shortcut: settings.quickShortcut) { [weak self] in
            self?.translateSelection(replace: false)
        }
        let replaceOK = !settings.selectionTranslationEnabled || hotKeys.register(id: 3, shortcut: settings.replaceShortcut) { [weak self] in
            self?.translateSelection(replace: true)
        }
        if !openOK || !quickOK || !replaceOK {
            settings.settingsMessage = L10n.string("Một phím tắt đang trùng với ứng dụng khác. Hãy chọn tổ hợp khác.")
        } else if settings.settingsMessage.contains("trùng") {
            settings.settingsMessage = L10n.string("Đã cập nhật phím tắt.")
        }
    }

    private func createMenuBar() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.button?.image = NSImage(systemSymbolName: "character.book.closed.fill", accessibilityDescription: "LinguaFacet")
            statusItem.button?.toolTip = "LinguaFacet — AI Translator"
        }

        let menu = NSMenu()
        menu.addItem(menuItem(L10n.string("Mở Dịch nhanh"), action: #selector(openMain), shortcut: settings.openShortcut))

        let stylesItem = NSMenuItem(title: L10n.string("Văn phong AI"), action: nil, keyEquivalent: "")
        let stylesMenu = NSMenu()
        stylesMenu.addItem(NSMenuItem(title: L10n.string("Mở Văn phong AI") + "…", action: #selector(openWritingStyle), keyEquivalent: ""))
        stylesMenu.addItem(.separator())
        for preset in settings.favoriteStylePresets {
            let item = NSMenuItem(title: preset.name, action: #selector(selectStylePreset(_:)), keyEquivalent: "")
            item.representedObject = preset.id.uuidString
            item.state = preset.id == styleModel.selectedPresetID ? .on : .off
            item.isEnabled = settings.stylePresetValidationMessage(for: preset.id) == nil
            stylesMenu.addItem(item)
        }
        stylesMenu.addItem(.separator())
        stylesMenu.addItem(NSMenuItem(title: L10n.string("Quản lý preset") + "…", action: #selector(openStyleSettings), keyEquivalent: ""))
        stylesItem.submenu = stylesMenu
        menu.addItem(stylesItem)
        menu.addItem(.separator())
        let quickSelectionItem = menuItem(L10n.string("Dịch nhanh vùng chọn"), action: #selector(quickTranslate), shortcut: settings.quickShortcut)
        quickSelectionItem.isEnabled = settings.selectionTranslationEnabled
        menu.addItem(quickSelectionItem)
        let replaceSelectionItem = menuItem(L10n.string("Dịch và thay thế"), action: #selector(replaceTranslate), shortcut: settings.replaceShortcut)
        replaceSelectionItem.isEnabled = settings.selectionTranslationEnabled
        menu.addItem(replaceSelectionItem)
        menu.addItem(.separator())

        let languagesItem = NSMenuItem(title: L10n.string("Ngôn ngữ"), action: nil, keyEquivalent: "")
        let languagesMenu = NSMenu()
        languagesMenu.addItem(languageMenuItem(for: .quickTranslate))
        languagesMenu.addItem(languageMenuItem(for: .writingStyle))
        languagesMenu.addItem(.separator())
        languagesMenu.addItem(NSMenuItem(title: L10n.string("Quản lý cặp ngôn ngữ") + "…", action: #selector(openLanguageSettings), keyEquivalent: ""))
        languagesItem.submenu = languagesMenu
        menu.addItem(languagesItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L10n.string("Cài đặt") + "…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L10n.string("Thoát LinguaFacet"), action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func menuItem(_ title: String, action: Selector, shortcut: GlobalShortcut) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: shortcut.menuKeyEquivalent)
        item.keyEquivalentModifierMask = shortcut.menuModifierFlags
        return item
    }

    private func languageMenuItem(for module: AppModule) -> NSMenuItem {
        let selection = settings.languageSelection(for: module)
        let item = NSMenuItem(
            title: "\(module.title) · \(selection.title)",
            action: nil,
            keyEquivalent: ""
        )
        let submenu = NSMenu()
        for pair in settings.favoritePairs {
            let pairItem = NSMenuItem(title: pair.title, action: #selector(selectPair(_:)), keyEquivalent: "")
            pairItem.representedObject = "\(module.rawValue)|\(pair.id.uuidString)"
            pairItem.state = pair.source == selection.source && pair.target == selection.target ? .on : .off
            submenu.addItem(pairItem)
        }
        if settings.favoritePairs.isEmpty {
            let empty = NSMenuItem(title: L10n.string("Chưa có cặp yêu thích"), action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
        }
        item.submenu = submenu
        return item
    }

    @objc private func openMain() { showMainWindow(module: .quickTranslate) }
    @objc private func openWritingStyle() { showMainWindow(module: .writingStyle) }
    @objc private func openStyleSettings() {
        settings.selectedSettingsTab = .styles
        showSettings()
    }
    @objc private func openLanguageSettings() {
        settings.selectedSettingsTab = .languages
        showSettings()
    }
    @objc private func quickTranslate() { translateSelection(replace: false) }
    @objc private func replaceTranslate() { translateSelection(replace: true) }
    @objc private func openSettings() { showSettings() }
    @objc private func quit() { NSApplication.shared.terminate(nil) }

    @objc private func selectPair(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String else { return }
        let components = raw.split(separator: "|", maxSplits: 1).map(String.init)
        guard components.count == 2,
              let module = AppModule(rawValue: components[0]),
              let id = UUID(uuidString: components[1]),
              let pair = settings.favoritePairs.first(where: { $0.id == id }) else { return }
        settings.applyPair(pair, to: module)
        showMainWindow(module: module)
    }

    @objc private func selectStylePreset(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let id = UUID(uuidString: raw) else { return }
        styleModel.selectPreset(id)
        createMenuBar()
        showMainWindow(module: .writingStyle)
    }

    private func showMainWindow(module: AppModule? = nil) {
        if let module { model.selectedModule = module }
        model.mode = .manual
        mainWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func resizeMainWindow(to requestedHeight: CGFloat) {
        guard let mainWindow else { return }
        let maximumHeight = maximumMainWindowHeight(for: mainWindow)
        mainWindow.maxSize.height = maximumHeight
        let height = min(maximumHeight, max(mainWindow.minSize.height, requestedHeight))
        guard abs(mainWindow.frame.height - height) > 1 else { return }
        var frame = mainWindow.frame
        frame.origin.y = frame.maxY - height
        frame.size.height = height
        let shouldAnimate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        mainWindow.setFrame(frame, display: true, animate: shouldAnimate)
    }

    private func showSettings() {
        selection.refreshAccessibilityStatus()
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showGroqKeyOnboardingIfNeeded(module: AppModule) -> Bool {
        guard settings.shouldPresentGroqKeyOnboarding else { return false }
        settings.markGroqKeyOnboardingPresented()
        showMainWindow(module: module)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.string("Thiết lập Groq để bắt đầu dịch")
        alert.informativeText = L10n.string("LinguaFacet chọn Groq làm dịch vụ chính vì phản hồi nhanh, hỗ trợ tốt nhiều ngôn ngữ và dùng được trên cả máy không có Apple Intelligence. API key do chính bạn tạo và chỉ được lưu trong macOS Keychain. Apple Local vẫn là phương án dự phòng khi khả dụng.")
        alert.addButton(withTitle: L10n.string("Thiết lập Groq"))
        alert.addButton(withTitle: L10n.string("Để sau"))
        alert.beginSheetModal(for: mainWindow) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            self.settings.selectedSettingsTab = .services
            self.settings.settingsMessage = L10n.string("Chọn “Hướng dẫn lấy API key”, tạo key trên Groq rồi quay lại dán và lưu tại đây.")
            self.showSettings()
        }
        return true
    }

    private func translateSelection(replace: Bool) {
        guard settings.selectionTranslationEnabled else {
            model.errorMessage = L10n.string("Dịch vùng chọn đang tắt trong Cài đặt.")
            showMainWindow(module: .quickTranslate)
            return
        }
        guard !model.isTranslating else { return }
        Task {
            do {
                let text = try await selection.copySelection()
                model.beginQuick(text: text, replace: replace)
                showQuickPanel()
            } catch {
                model.errorMessage = error.localizedDescription
                model.sourceText = ""
                model.translatedText = ""
                model.mode = .quickPreview
                showQuickPanel()
            }
        }
    }

    private func showQuickPanel() {
        let mouse = NSEvent.mouseLocation
        let size = quickPanel.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        var origin = NSPoint(x: mouse.x + 14, y: mouse.y - size.height - 14)
        origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        origin.y = min(max(origin.y, visible.minY + 8), visible.maxY - size.height - 8)
        quickPanel.setFrameOrigin(origin)
        quickPanel.orderFrontRegardless()
    }

    private func applyAlwaysOnTop(_ enabled: Bool) {
        mainWindow?.level = enabled ? .floating : .normal
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window === mainWindow,
              settings.quitWhenMainWindowCloses else { return }
        NSApp.terminate(nil)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isShowingQuitConfirmation else { return .terminateLater }
        isShowingQuitConfirmation = true
        showMainWindow(module: model.selectedModule)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSApplication.shared.applicationIconImage
        alert.messageText = L10n.string("Bạn muốn thoát LinguaFacet?")

        var message = L10n.string("Cảm ơn bạn đã sử dụng LinguaFacet. Nếu ứng dụng giúp bạn tiết kiệm thời gian, bạn có thể ủng hộ mình trên Ko-fi để mình tiếp tục sửa lỗi và cải thiện. Hoàn toàn tự nguyện.")
        if model.isTranslating || styleModel.isWorking {
            message += "\n\n" + L10n.string("Bản dịch đang chạy sẽ dừng khi bạn thoát.")
        }
        alert.informativeText = message
        alert.addButton(withTitle: L10n.string("Ở lại"))
        alert.addButton(withTitle: L10n.string("Thoát"))
        alert.addButton(withTitle: L10n.string("Ủng hộ trên Ko-fi"))

        alert.buttons[0].keyEquivalent = "\r"

        quitAlert = alert
        quitEscapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak alert] event in
            guard event.keyCode == 53, let self, let alert else { return event }
            alert.window.sheetParent?.endSheet(alert.window, returnCode: .abort)
            self.removeQuitEscapeMonitor()
            return nil
        }

        alert.beginSheetModal(for: mainWindow) { [weak self, weak sender] response in
            guard let self, let sender else { return }
            self.removeQuitEscapeMonitor()
            self.quitAlert = nil
            self.isShowingQuitConfirmation = false

            let first = NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
            let action = QuitConfirmationAction.resolve(buttonIndex: response.rawValue - first)
            switch action {
            case .stay:
                sender.reply(toApplicationShouldTerminate: false)
            case .quit:
                sender.reply(toApplicationShouldTerminate: true)
            case .support:
                sender.reply(toApplicationShouldTerminate: false)
                if !self.settings.openSupportPage() {
                    self.settings.selectedSettingsTab = .about
                    self.showSettings()
                }
            }
        }
        return .terminateLater
    }

    private func removeQuitEscapeMonitor() {
        if let quitEscapeMonitor {
            NSEvent.removeMonitor(quitEscapeMonitor)
            self.quitEscapeMonitor = nil
        }
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard sender === mainWindow else { return frameSize }
        let maximumHeight = maximumMainWindowHeight(for: sender)
        return NSSize(
            width: max(frameSize.width, TQLayout.mainWindowMinWidth),
            height: min(
                maximumHeight,
                max(frameSize.height, TQLayout.mainWindowMinHeight)
            )
        )
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === mainWindow else { return }
        configureMainWindowSizeLimits()
        resizeMainWindow(to: window.frame.height)
    }
}

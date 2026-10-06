import AppKit
import Foundation
import ServiceManagement

@MainActor
final class SettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var interfaceLanguage: InterfaceLanguage {
        didSet {
            save(interfaceLanguage.rawValue, L10n.defaultsKey)
            onInterfaceLanguageChanged?()
            onMenuConfigurationChanged?()
        }
    }

    @Published var provider: TranslationProvider {
        didSet { save(provider.rawValue, "provider"); onMenuConfigurationChanged?() }
    }
    @Published var quickSourceLanguage: AppLanguage {
        didSet { save(quickSourceLanguage.rawValue, "quickSourceLanguage"); onMenuConfigurationChanged?() }
    }
    @Published var quickTargetLanguage: AppLanguage {
        didSet { save(quickTargetLanguage.rawValue, "quickTargetLanguage"); onMenuConfigurationChanged?() }
    }
    @Published var styleSourceLanguage: AppLanguage {
        didSet { save(styleSourceLanguage.rawValue, "styleSourceLanguage"); onMenuConfigurationChanged?() }
    }
    @Published var styleTargetLanguage: AppLanguage {
        didSet { save(styleTargetLanguage.rawValue, "styleTargetLanguage"); onMenuConfigurationChanged?() }
    }
    @Published var autoCopy: Bool { didSet { save(autoCopy, "autoCopy") } }
    @Published var alwaysOnTop: Bool {
        didSet {
            save(alwaysOnTop, "alwaysOnTop")
            onAlwaysOnTopChanged?(alwaysOnTop)
        }
    }
    @Published var closeQuickAfterCopy: Bool { didSet { save(closeQuickAfterCopy, "closeQuickAfterCopy") } }
    @Published var selectionTranslationEnabled: Bool {
        didSet {
            save(selectionTranslationEnabled, "selectionTranslationEnabled")
            onShortcutsChanged?()
            onMenuConfigurationChanged?()
        }
    }
    @Published var quitWhenMainWindowCloses: Bool {
        didSet { save(quitWhenMainWindowCloses, "quitWhenMainWindowCloses") }
    }
    @Published var theme: AppTheme {
        didSet {
            save(theme.rawValue, "theme")
            applyTheme()
        }
    }

    @Published var groqKeyDraft = ""
    @Published private(set) var hasGroqKey: Bool
    @Published var groqTranslationModel: GroqModel {
        didSet { save(groqTranslationModel.rawValue, "groqTranslationModel") }
    }
    @Published var groqStyleModel: GroqModel {
        didSet { save(groqStyleModel.rawValue, "groqStyleModel") }
    }
    @Published var geminiKeyDraft = ""
    @Published private(set) var hasGeminiKey: Bool
    @Published var geminiModel: String { didSet { save(geminiModel, "geminiModel") } }
    @Published var launchAtLogin: Bool
    @Published var settingsMessage = ""
    @Published var supportMessage = ""
    @Published var selectedSettingsTab: SettingsTab = .general
    @Published private(set) var hasPresentedGroqKeyOnboarding: Bool
    @Published var favoritePairs: [LanguagePair] {
        didSet { saveCodable(favoritePairs, "favoritePairs"); onMenuConfigurationChanged?() }
    }
    @Published var stylePresets: [StylePreset] {
        didSet { saveCodable(stylePresets, "stylePresets"); onMenuConfigurationChanged?() }
    }
    @Published var protectedTermsText: String {
        didSet { save(protectedTermsText, "protectedTermsText") }
    }
    @Published var openShortcut: GlobalShortcut {
        didSet { saveCodable(openShortcut, "openShortcut"); onShortcutsChanged?() }
    }
    @Published var quickShortcut: GlobalShortcut {
        didSet { saveCodable(quickShortcut, "quickShortcut"); onShortcutsChanged?() }
    }
    @Published var replaceShortcut: GlobalShortcut {
        didSet { saveCodable(replaceShortcut, "replaceShortcut"); onShortcutsChanged?() }
    }

    var onAlwaysOnTopChanged: ((Bool) -> Void)?
    var onShortcutsChanged: (() -> Void)?
    var onMenuConfigurationChanged: (() -> Void)?
    var onInterfaceLanguageChanged: (() -> Void)?
    private var storedGroqKey: String
    private var storedGeminiKey: String

    private enum KeyStatusDefaults {
        static let groq = "hasSavedGroqKeyV2"
        static let gemini = "hasSavedGeminiKeyV2"
    }

    init() {
        interfaceLanguage = InterfaceLanguage(
            rawValue: defaults.string(forKey: L10n.defaultsKey) ?? ""
        ) ?? .english
        let previousProvider = TranslationProvider(rawValue: defaults.string(forKey: "provider") ?? "")
        storedGroqKey = ""
        storedGeminiKey = ""
        hasGroqKey = defaults.object(forKey: KeyStatusDefaults.groq) as? Bool
            ?? previousProvider.map { $0 == .groq }
            ?? false
        hasGeminiKey = defaults.object(forKey: KeyStatusDefaults.gemini) as? Bool
            ?? previousProvider.map { $0 == .gemini }
            ?? false
        groqTranslationModel = GroqModel(
            rawValue: defaults.string(forKey: "groqTranslationModel") ?? ""
        ) ?? .gptOSS120B
        groqStyleModel = GroqModel(
            rawValue: defaults.string(forKey: "groqStyleModel") ?? ""
        ) ?? .gptOSS120B

        let groqPrimaryMigrationKey = "didPromoteGroqToPrimaryV1"
        let shouldPromoteGroq = !defaults.bool(forKey: groqPrimaryMigrationKey)
        provider = shouldPromoteGroq ? .groq : (previousProvider ?? .groq)
        let legacySelection = ModuleLanguageSelection(
            source: AppLanguage(rawValue: defaults.string(forKey: "sourceLanguage") ?? "auto") ?? .automatic,
            target: AppLanguage(rawValue: defaults.string(forKey: "targetLanguage") ?? "vi") ?? .vietnamese
        )
        let quickSelection = ModuleLanguageSelection.resolved(
            savedSource: defaults.string(forKey: "quickSourceLanguage").flatMap(AppLanguage.init(rawValue:)),
            savedTarget: defaults.string(forKey: "quickTargetLanguage").flatMap(AppLanguage.init(rawValue:)),
            legacy: legacySelection
        )
        let styleSelection = ModuleLanguageSelection.resolved(
            savedSource: defaults.string(forKey: "styleSourceLanguage").flatMap(AppLanguage.init(rawValue:)),
            savedTarget: defaults.string(forKey: "styleTargetLanguage").flatMap(AppLanguage.init(rawValue:)),
            legacy: legacySelection
        )
        quickSourceLanguage = quickSelection.source
        quickTargetLanguage = quickSelection.target
        styleSourceLanguage = styleSelection.source
        styleTargetLanguage = styleSelection.target
        autoCopy = defaults.object(forKey: "autoCopy") as? Bool ?? false
        alwaysOnTop = defaults.object(forKey: "alwaysOnTop") as? Bool ?? false
        closeQuickAfterCopy = defaults.object(forKey: "closeQuickAfterCopy") as? Bool ?? true
        selectionTranslationEnabled = defaults.object(forKey: "selectionTranslationEnabled") as? Bool ?? true
        quitWhenMainWindowCloses = defaults.object(forKey: "quitWhenMainWindowCloses") as? Bool ?? false
        theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "system") ?? .system
        geminiModel = defaults.string(forKey: "geminiModel") ?? "gemini-2.5-flash"
        launchAtLogin = SMAppService.mainApp.status == .enabled
        hasPresentedGroqKeyOnboarding = defaults.bool(forKey: "didShowGroqKeyOnboardingV1")
        favoritePairs = Self.decode([LanguagePair].self, key: "favoritePairs", defaults: defaults) ?? [
            LanguagePair(source: .automatic, target: .vietnamese),
            LanguagePair(source: .japanese, target: .vietnamese),
            LanguagePair(source: .english, target: .vietnamese),
            LanguagePair(source: .vietnamese, target: .english),
            LanguagePair(source: .vietnamese, target: .japanese)
        ]
        let savedPresets = Self.decode([StylePreset].self, key: "stylePresets", defaults: defaults)
        let initialPresets = savedPresets?.isEmpty == false ? savedPresets! : StylePreset.defaults
        stylePresets = StylePreset.upgradeLegacyBuiltInPrompts(initialPresets)
        protectedTermsText = defaults.string(forKey: "protectedTermsText") ?? ""
        openShortcut = Self.decode(GlobalShortcut.self, key: "openShortcut", defaults: defaults) ?? .openWindow
        quickShortcut = Self.decode(GlobalShortcut.self, key: "quickShortcut", defaults: defaults) ?? .quickTranslate
        replaceShortcut = Self.decode(GlobalShortcut.self, key: "replaceShortcut", defaults: defaults) ?? .replaceTranslate
        defaults.set(provider.rawValue, forKey: "provider")
        defaults.set(quickSourceLanguage.rawValue, forKey: "quickSourceLanguage")
        defaults.set(quickTargetLanguage.rawValue, forKey: "quickTargetLanguage")
        defaults.set(styleSourceLanguage.rawValue, forKey: "styleSourceLanguage")
        defaults.set(styleTargetLanguage.rawValue, forKey: "styleTargetLanguage")
        defaults.set(true, forKey: groqPrimaryMigrationKey)
        saveCodable(stylePresets, "stylePresets")
        applyTheme()
    }

    var shouldPresentGroqKeyOnboarding: Bool {
        GroqKeyOnboardingPolicy.shouldPresent(
            provider: provider,
            hasKey: hasGroqKey,
            hasPresented: hasPresentedGroqKeyOnboarding
        )
    }

    func markGroqKeyOnboardingPresented() {
        hasPresentedGroqKeyOnboarding = true
        defaults.set(true, forKey: "didShowGroqKeyOnboardingV1")
    }

    var groqKeyForRequest: String {
        if storedGroqKey.isEmpty, hasGroqKey {
            storedGroqKey = KeychainStore.read("groq")
            if storedGroqKey.isEmpty {
                hasGroqKey = false
                defaults.set(false, forKey: KeyStatusDefaults.groq)
            }
        }
        return storedGroqKey
    }

    var geminiKeyForRequest: String {
        if storedGeminiKey.isEmpty, hasGeminiKey {
            storedGeminiKey = KeychainStore.read("gemini")
            if storedGeminiKey.isEmpty {
                hasGeminiKey = false
                defaults.set(false, forKey: KeyStatusDefaults.gemini)
            }
        }
        return storedGeminiKey
    }

    func saveGroqKey() {
        let value = groqKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            settingsMessage = "Hãy nhập Groq API key trước khi lưu."
            return
        }
        do {
            try KeychainStore.set(value, account: "groq")
            storedGroqKey = value
            groqKeyDraft = ""
            hasGroqKey = true
            defaults.set(true, forKey: KeyStatusDefaults.groq)
            settingsMessage = "Đã lưu Groq API key trong Keychain."
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    func deleteGroqKey() {
        do {
            try KeychainStore.set("", account: "groq")
            storedGroqKey = ""
            groqKeyDraft = ""
            hasGroqKey = false
            defaults.set(false, forKey: KeyStatusDefaults.groq)
            settingsMessage = "Đã xóa Groq API key khỏi Keychain."
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    func saveGeminiKey() {
        let value = geminiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            settingsMessage = "Hãy nhập Gemini API key trước khi lưu."
            return
        }
        do {
            try KeychainStore.set(value, account: "gemini")
            storedGeminiKey = value
            geminiKeyDraft = ""
            hasGeminiKey = true
            defaults.set(true, forKey: KeyStatusDefaults.gemini)
            settingsMessage = "Đã lưu Gemini API key trong Keychain."
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    func deleteGeminiKey() {
        do {
            try KeychainStore.set("", account: "gemini")
            storedGeminiKey = ""
            geminiKeyDraft = ""
            hasGeminiKey = false
            defaults.set(false, forKey: KeyStatusDefaults.gemini)
            settingsMessage = "Đã xóa Gemini API key khỏi Keychain."
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    func openGroqKeyGuide() {
        guard let url = URL(string: "https://console.groq.com/keys") else { return }
        NSWorkspace.shared.open(url)
    }

    @discardableResult
    func openSupportPage() -> Bool {
        supportMessage = ""
        guard NSWorkspace.shared.open(SupportDestination.url) else {
            supportMessage = "Không thể mở trình duyệt. Bạn có thể truy cập thủ công: \(SupportDestination.urlString)"
            selectedSettingsTab = .about
            return false
        }
        return true
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            settingsMessage = enabled ? "Đã bật mở cùng macOS." : "Đã tắt mở cùng macOS."
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            settingsMessage = "Không thể thay đổi: \(error.localizedDescription)"
        }
    }

    func applyTheme() {
        switch theme {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    func languageSelection(for module: AppModule) -> ModuleLanguageSelection {
        switch module {
        case .quickTranslate:
            ModuleLanguageSelection(source: quickSourceLanguage, target: quickTargetLanguage)
        case .writingStyle:
            ModuleLanguageSelection(source: styleSourceLanguage, target: styleTargetLanguage)
        }
    }

    func applyPair(_ pair: LanguagePair, to module: AppModule) {
        switch module {
        case .quickTranslate:
            quickSourceLanguage = pair.source
            quickTargetLanguage = pair.target
        case .writingStyle:
            styleSourceLanguage = pair.source
            styleTargetLanguage = pair.target
        }
    }

    func addFavoritePair() {
        guard favoritePairs.count < 10 else {
            settingsMessage = "Có thể lưu tối đa 10 cặp ngôn ngữ."
            return
        }
        favoritePairs.append(LanguagePair(source: .automatic, target: .vietnamese))
    }

    func removeFavoritePair(id: UUID) {
        favoritePairs.removeAll { $0.id == id }
    }

    var favoriteStylePresets: [StylePreset] {
        stylePresets.filter { $0.isFavorite }
    }

    func addStylePreset() -> UUID? {
        guard stylePresets.count < 20 else {
            settingsMessage = "Có thể lưu tối đa 20 preset văn phong."
            return nil
        }
        let existingNames = Set(stylePresets.map { $0.name.lowercased() })
        var number = 1
        var name = "Preset mới"
        while existingNames.contains(name.lowercased()) {
            number += 1
            name = "Preset mới \(number)"
        }
        let preset = StylePreset(
            id: UUID(),
            name: name,
            prompt: "Infer the medium and audience only from evidence in the source; otherwise use a neutral register. Use clear, natural target-language diction, collocations, syntax, and sentence rhythm appropriate to that audience. Preserve every fact, referent, condition, name, number, negation, uncertainty marker, speech-act force, relationship, urgency, and commitment. Do not invent a greeting, apology, promise, emotion, slang, explanation, or new information.",
            symbol: "sparkles",
            isFavorite: true,
            builtIn: nil
        )
        stylePresets.append(preset)
        settingsMessage = "Đã tạo \(name)."
        return preset.id
    }

    func removeStylePreset(id: UUID) {
        guard let preset = stylePresets.first(where: { $0.id == id }), !preset.isBuiltIn else {
            settingsMessage = "Preset mặc định không thể xóa; bạn có thể ẩn hoặc khôi phục nó."
            return
        }
        if preset.isFavorite && favoriteStylePresets.count == 1 {
            settingsMessage = "Cần giữ ít nhất một preset trên thanh chọn nhanh."
            return
        }
        stylePresets.removeAll { $0.id == id }
        settingsMessage = "Đã xóa preset \(preset.name)."
    }

    func setStylePresetFavorite(id: UUID, favorite: Bool) {
        guard let index = stylePresets.firstIndex(where: { $0.id == id }) else { return }
        if !favorite && stylePresets[index].isFavorite && favoriteStylePresets.count == 1 {
            settingsMessage = "Cần giữ ít nhất một preset trên thanh chọn nhanh."
            return
        }
        stylePresets[index].isFavorite = favorite
        settingsMessage = favorite
            ? "Đã đưa \(stylePresets[index].name) ra thanh chọn nhanh."
            : "Đã ẩn \(stylePresets[index].name) khỏi thanh chọn nhanh."
    }

    func resetStylePreset(id: UUID) {
        guard let index = stylePresets.firstIndex(where: { $0.id == id }),
              let kind = stylePresets[index].builtIn else { return }
        let wasFavorite = stylePresets[index].isFavorite
        stylePresets[index] = StylePreset.defaultPreset(for: kind)
        stylePresets[index].isFavorite = wasFavorite
        settingsMessage = "Đã khôi phục preset mặc định."
    }

    func applyStyleTemplate(_ template: StylePromptTemplate, to id: UUID) {
        guard let index = stylePresets.firstIndex(where: { $0.id == id }) else { return }
        stylePresets[index].prompt = template.prompt
        stylePresets[index].symbol = template.symbol
        settingsMessage = "Đã áp dụng mẫu “\(template.name)”."
    }

    func stylePresetValidationMessage(for id: UUID) -> String? {
        guard let preset = stylePresets.first(where: { $0.id == id }) else { return nil }
        if preset.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Tên preset không được để trống."
        }
        let duplicateCount = stylePresets.filter {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(preset.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
        }.count
        if duplicateCount > 1 { return "Tên preset đang trùng với preset khác." }
        if preset.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Prompt không được để trống."
        }
        if preset.prompt.count < 30 {
            return "Prompt quá ngắn; hãy mô tả rõ giọng điệu và giới hạn."
        }
        return nil
    }

    func resetShortcuts() {
        openShortcut = .openWindow
        quickShortcut = .quickTranslate
        replaceShortcut = .replaceTranslate
        settingsMessage = "Đã khôi phục phím tắt mặc định."
    }

    private func save(_ value: Any, _ key: String) { defaults.set(value, forKey: key) }

    private func saveCodable<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }

    private static func decode<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

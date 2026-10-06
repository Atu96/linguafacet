import AppKit
import NaturalLanguage
import SwiftUI
import Translation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedModule: AppModule = .quickTranslate
    @Published var sourceText = ""
    @Published var translatedText = ""
    @Published var status = "Sẵn sàng"
    @Published var errorMessage = ""
    @Published var isTranslating = false
    @Published var configuration: TranslationSession.Configuration?
    @Published var mode: TranslationMode = .manual
    @Published var detectedLanguage = ""

    let settings: SettingsStore
    private let speech = SpeechService()
    private var requestID = UUID()
    private var autoTranslateTask: Task<Void, Never>?
    private var remoteTask: Task<Void, Never>?
    private var appleFallbackMessage: String?

    var onQuickResult: (() -> Void)?
    var onReplaceResult: ((String) -> Void)?
    var onQuickCopy: (() -> Void)?
    var onRequestMainWindow: (() -> Void)?
    var onRequestSettings: (() -> Void)?
    var onRequestGroqKeyOnboarding: (() -> Bool)?
    var onPreferredWindowHeight: ((CGFloat) -> Void)?

    init(settings: SettingsStore) { self.settings = settings }

    func translateManual() {
        mode = .manual
        translate()
    }

    func scheduleAutoTranslation() {
        guard mode == .manual else { return }
        autoTranslateTask?.cancel()
        remoteTask?.cancel()
        requestID = UUID()
        isTranslating = false

        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            translatedText = ""
            errorMessage = ""
            detectedLanguage = ""
            status = "Sẵn sàng"
            return
        }

        status = "Đang chờ bạn nhập xong…"
        autoTranslateTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(480))
            guard !Task.isCancelled, let self else { return }
            self.translateManual()
        }
    }

    func beginQuick(text: String, replace: Bool) {
        sourceText = text
        translatedText = ""
        mode = replace ? .quickReplace : .quickPreview
        translate()
    }

    func translate() {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            errorMessage = "Hãy nhập hoặc dán nội dung cần dịch."
            status = "Chưa có nội dung"
            return
        }
        if settings.provider == .groq,
           !settings.hasGroqKey,
           onRequestGroqKeyOnboarding?() == true {
            isTranslating = false
            status = "Cần thiết lập Groq để bắt đầu"
            return
        }
        requestID = UUID()
        updateDetectedLanguage(for: text)
        let currentID = requestID
        remoteTask?.cancel()
        appleFallbackMessage = nil
        errorMessage = ""
        isTranslating = true
        status = "Đang dịch bằng \(settings.provider.title)…"

        if settings.provider == .apple {
            prepareAppleTranslation()
        } else {
            configuration = nil
            let remote = RemoteTranslationConfiguration(
                provider: settings.provider,
                groqKey: settings.groqKeyForRequest,
                groqModel: settings.groqTranslationModel,
                geminiKey: settings.geminiKeyForRequest,
                geminiModel: settings.geminiModel
            )
            remoteTask = Task {
                do {
                    let result = try await TranslationServices.translate(
                        text: text,
                        source: settings.quickSourceLanguage,
                        target: settings.quickTargetLanguage,
                        configuration: remote
                    )
                    guard currentID == requestID else { return }
                    finish(result)
                } catch {
                    guard currentID == requestID else { return }
                    if settings.provider == .groq {
                        beginAppleFallback(after: error)
                    } else {
                        fail(error)
                    }
                }
            }
        }
    }

    func translate(using session: TranslationSession) async {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentID = requestID
        do {
            let response = try await session.translate(text)
            guard currentID == requestID else { return }
            detectedLanguage = AppLanguage.matching(response.sourceLanguage.minimalIdentifier)?.title
                ?? response.sourceLanguage.minimalIdentifier
            if let fallback = appleFallbackMessage {
                finish(
                    response.targetText,
                    status: "Đã dùng Apple Local dự phòng · \(fallback)"
                )
                appleFallbackMessage = nil
            } else {
                finish(response.targetText)
            }
        } catch {
            guard currentID == requestID else { return }
            if let fallback = appleFallbackMessage {
                appleFallbackMessage = nil
                fail(
                    TranslationServiceError.fallbackFailed(
                        "\(fallback) Apple Local cũng không hoàn tất: \(friendlyMessage(for: error))"
                    )
                )
            } else {
                fail(error)
            }
        }
    }

    func cancel() {
        autoTranslateTask?.cancel()
        remoteTask?.cancel()
        requestID = UUID()
        configuration = nil
        appleFallbackMessage = nil
        isTranslating = false
        status = "Đã hủy"
    }

    func retry() {
        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        translate()
    }

    func clear() {
        cancel()
        sourceText = ""
        translatedText = ""
        errorMessage = ""
        detectedLanguage = ""
        status = "Sẵn sàng"
    }

    func pasteSource() {
        if let value = NSPasteboard.general.string(forType: .string) {
            sourceText = value
            status = "Đã dán nội dung"
        }
    }

    func copyResult() {
        guard !translatedText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
        status = "Đã sao chép bản dịch"
        if mode == .quickPreview, settings.closeQuickAfterCopy { onQuickCopy?() }
    }

    func replaceWithResult() {
        guard !translatedText.isEmpty else { return }
        onReplaceResult?(translatedText)
    }

    func openInMainWindow() {
        mode = .manual
        onRequestMainWindow?()
    }

    func swapLanguages() {
        let source = settings.quickSourceLanguage
        if source == .automatic {
            if let detected = AppLanguage.allCases.first(where: { $0.title == detectedLanguage }) {
                settings.quickSourceLanguage = settings.quickTargetLanguage
                settings.quickTargetLanguage = detected
            } else {
                settings.quickSourceLanguage = settings.quickTargetLanguage
                settings.quickTargetLanguage = .english
            }
        } else {
            settings.quickSourceLanguage = settings.quickTargetLanguage
            settings.quickTargetLanguage = source
        }
        if !translatedText.isEmpty {
            let old = sourceText
            sourceText = translatedText
            translatedText = old
        }
    }

    func speakSource() { speech.speak(sourceText, language: settings.quickSourceLanguage) }
    func speakResult() { speech.speak(translatedText, language: settings.quickTargetLanguage) }

    private func updateDetectedLanguage(for text: String) {
        guard settings.quickSourceLanguage == .automatic else {
            detectedLanguage = ""
            return
        }
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        guard letters >= 4 else {
            detectedLanguage = ""
            return
        }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let code = recognizer.dominantLanguage?.rawValue else {
            detectedLanguage = ""
            return
        }
        detectedLanguage = AppLanguage.matching(code)?.title ?? code
    }

    private func prepareAppleTranslation() {
        var next = TranslationSession.Configuration(
            source: settings.quickSourceLanguage.localeLanguage,
            target: settings.quickTargetLanguage.localeLanguage
        )
        if #available(macOS 26.4, *) {
            next = TranslationSession.Configuration(
                source: settings.quickSourceLanguage.localeLanguage,
                target: settings.quickTargetLanguage.localeLanguage,
                preferredStrategy: .highFidelity
            )
        }
        if configuration == next {
            configuration?.invalidate()
        } else {
            configuration = next
        }
    }

    private func beginAppleFallback(after error: Error) {
        let reason = friendlyMessage(for: error)
        appleFallbackMessage = reason
        errorMessage = ""
        status = "Groq không khả dụng, đang dùng Apple Local…"
        prepareAppleTranslation()
    }

    private func finish(_ result: String, status customStatus: String? = nil) {
        translatedText = result.trimmingCharacters(in: .whitespacesAndNewlines)
        isTranslating = false
        status = customStatus ?? "Đã dịch bằng \(settings.provider.title)"
        if settings.autoCopy { copyResult() }
        switch mode {
        case .manual: break
        case .quickPreview: onQuickResult?()
        case .quickReplace: onReplaceResult?(translatedText)
        }
    }

    private func fail(_ error: Error) {
        isTranslating = false
        errorMessage = friendlyMessage(for: error)
        status = "Dịch không thành công"
        if mode != .manual { onQuickResult?() }
    }

    private func friendlyMessage(for error: Error) -> String {
        let raw = error.localizedDescription
        if raw.localizedCaseInsensitiveContains("download") || raw.localizedCaseInsensitiveContains("installed") {
            return "macOS chưa có model cho cặp ngôn ngữ này. Hãy cho phép tải model rồi thử lại."
        }
        return raw
    }
}

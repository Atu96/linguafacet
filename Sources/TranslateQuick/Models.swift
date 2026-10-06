import AppKit
import Foundation
import NaturalLanguage

enum TranslationProvider: String, CaseIterable, Identifiable {
    case groq
    case apple
    case gemini

    var id: String { rawValue }

    var title: String {
        switch self {
        case .groq: "Groq"
        case .apple: "Apple Local AI"
        case .gemini: "Google Gemini"
        }
    }

    var symbol: String {
        switch self {
        case .groq: "bolt.fill"
        case .apple: "apple.intelligence"
        case .gemini: "diamond.fill"
        }
    }
}

enum GroqModel: String, CaseIterable, Identifiable, Codable {
    case gptOSS120B = "openai/gpt-oss-120b"
    case qwen36_27B = "qwen/qwen3.6-27b"
    case gptOSS20B = "openai/gpt-oss-20b"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gptOSS120B: L10n.string("GPT-OSS 120B · Khuyên dùng")
        case .qwen36_27B: L10n.string("Qwen 3.6 27B · Nhật/Trung · Preview")
        case .gptOSS20B: L10n.string("GPT-OSS 20B · Nhanh, tiết kiệm")
        }
    }

    var compactTitle: String {
        switch self {
        case .gptOSS120B: "GPT-OSS 120B"
        case .qwen36_27B: "Qwen 3.6 27B"
        case .gptOSS20B: "GPT-OSS 20B"
        }
    }

    var reasoningEffort: String {
        switch self {
        case .gptOSS120B, .gptOSS20B: "low"
        case .qwen36_27B: "none"
        }
    }

    var includesReasoningParameter: Bool {
        switch self {
        case .gptOSS120B, .gptOSS20B: true
        case .qwen36_27B: false
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case automatic = "auto"
    case vietnamese = "vi"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case russian = "ru"
    case thai = "th"
    case indonesian = "id"

    var id: String { rawValue }

    var title: String {
        if self == .automatic { return L10n.string("Tự động nhận diện") }
        let locale = Locale(identifier: L10n.currentLanguage.rawValue)
        return locale.localizedString(forIdentifier: rawValue)?.capitalized(with: locale)
            ?? rawValue
    }

    /// Stable English language name for API prompts. UI localization must never
    /// change prompt semantics or consume extra model tokens unpredictably.
    var promptName: String {
        switch self {
        case .automatic: "automatically detected language"
        case .vietnamese: "Vietnamese"
        case .english: "English"
        case .japanese: "Japanese"
        case .korean: "Korean"
        case .simplifiedChinese: "Simplified Chinese"
        case .traditionalChinese: "Traditional Chinese"
        case .french: "French"
        case .german: "German"
        case .spanish: "Spanish"
        case .russian: "Russian"
        case .thai: "Thai"
        case .indonesian: "Indonesian"
        }
    }

    var localeLanguage: Locale.Language? {
        self == .automatic ? nil : Locale.Language(identifier: rawValue)
    }

    static func matching(_ identifier: String) -> AppLanguage? {
        let normalized = identifier.lowercased()
        return allCases.first {
            normalized == $0.rawValue.lowercased() ||
            normalized.hasPrefix($0.rawValue.lowercased() + "-")
        }
    }
}

enum TranslationMode {
    case manual
    case quickPreview
    case quickReplace
}

enum AppModule: String, CaseIterable {
    case quickTranslate
    case writingStyle

    var title: String {
        switch self {
        case .quickTranslate: L10n.string("Dịch nhanh")
        case .writingStyle: L10n.string("Văn phong AI")
        }
    }

    var symbol: String {
        switch self {
        case .quickTranslate: "character.book.closed.fill"
        case .writingStyle: "textformat.alt"
        }
    }
}

struct ModuleLanguageSelection: Equatable {
    let source: AppLanguage
    let target: AppLanguage

    init(source: AppLanguage, target: AppLanguage) {
        self.source = source
        self.target = target == .automatic ? .vietnamese : target
    }

    static func resolved(
        savedSource: AppLanguage?,
        savedTarget: AppLanguage?,
        legacy: ModuleLanguageSelection
    ) -> ModuleLanguageSelection {
        ModuleLanguageSelection(
            source: savedSource ?? legacy.source,
            target: savedTarget ?? legacy.target
        )
    }

    var title: String {
        LanguagePair(source: source, target: target).title
    }
}

enum SettingsTab: String, Hashable {
    case general
    case languages
    case styles
    case services
    case shortcuts
    case about
}

enum SupportDestination {
    static let urlString = "https://ko-fi.com/atu1202"
    static let url = URL(string: urlString)!
}

enum QuitConfirmationAction: Equatable {
    case stay
    case quit
    case support

    static func resolve(buttonIndex: Int) -> QuitConfirmationAction {
        switch buttonIndex {
        case 1: .quit
        case 2: .support
        default: .stay
        }
    }
}

struct GroqKeyOnboardingPolicy {
    static func shouldPresent(
        provider: TranslationProvider,
        hasKey: Bool,
        hasPresented: Bool
    ) -> Bool {
        provider == .groq && !hasKey && !hasPresented
    }
}

enum BuiltInStylePreset: String, Codable, Hashable {
    case naturalConversation
    case academic
    case professional
    case peers
}

struct StylePreset: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var prompt: String
    var symbol: String
    var isFavorite: Bool
    var builtIn: BuiltInStylePreset?

    var isBuiltIn: Bool { builtIn != nil }

    var guidance: String? {
        switch builtIn {
        case .naturalConversation:
            return "Tự nhận diện hội thoại, chat hay lời nhắn; ưu tiên cách nói bản ngữ nhưng không tự dựng thêm quan hệ hoặc cảm xúc."
        case .academic:
            return "Tự nhận diện ngành và thể loại học thuật từ chính nội dung; giữ đúng thuật ngữ, logic và mức độ bằng chứng."
        case .professional:
            return "Tự nhận diện chat nội bộ, email, quản lý hay đối tác; lịch sự đúng chuẩn nhưng không đổi trách nhiệm hoặc độ khẩn."
        case .peers:
            return "Khẩu ngữ nhẹ giữa người ngang hàng; không tự thêm lời chào, tiếng lóng, thân mật hoặc phấn khích."
        case nil:
            return nil
        }
    }

    static let availableSymbols = [
        "bubble.left.and.bubble.right.fill", "graduationcap.fill", "briefcase.fill",
        "person.2.fill", "heart.text.square.fill", "envelope.fill", "text.book.closed.fill",
        "ellipsis.bubble.fill", "sparkles", "slider.horizontal.3"
    ]

    private static let naturalConversationPrompt = """
    Render the translation as natural everyday one-to-one communication. Infer from the source alone whether it is spoken dialogue, chat, a personal message, or neutral prose; if the medium is unclear, use a neutral conversational register. Prefer native target-language collocations, information order, pronoun choices, and sentence rhythm instead of translation-shaped syntax. Use contractions, particles, ellipsis, or sentence fragments only when they are normal in the target language and supported by the source's relationship and rhythm. Preserve the same communicative act, social distance, hesitation, directness, emotion, and boundaries. Do not manufacture a greeting, slang, humor, intimacy, enthusiasm, or cultural reference merely to make the result sound conversational.
    """

    private static let academicPrompt = """
    Infer the academic field and document genre only from terminology, symbols, structure, and claims present in the source. Possible fields include mathematics, physical sciences, engineering, computing, medicine, life sciences, law, economics, business, education, social sciences, humanities, and interdisciplinary work; possible genres include a paper, thesis, abstract, textbook passage, lecture note, problem statement, definition, or scholarly discussion. Use established target-language terminology and genre conventions for the detected field. If the field or a term is ambiguous, choose the most semantically neutral established equivalent and do not invent specialization. Write disciplined academic prose with precise logical relations and an objective register. Preserve evidential and epistemic force exactly: possibility, probability, hypothesis, correlation, causation, observation, proof, limitation, and conclusion must never be promoted or weakened. Preserve definitions, quantifier scope, formulas, variables, units, citations, quotations, methodology, qualifications, and limitations. Do not add background explanation, references, claims, transitions, or disciplinary context that the source does not support.
    """

    private static let professionalPrompt = """
    Render the translation in concise, polished workplace language. Infer the communication channel and recipient relationship only when the source supports it: for example internal chat, email, meeting note, colleague, manager, direct report, client, or partner; otherwise use a neutral professional register. Prefer native target-language business collocations, clear sentence structure, and an actionable presentation of the actor, request, decision, deadline, or next step only when those elements already exist in the source. Surface courtesy may be adapted to normal professional conventions, but preserve the exact speech-act force, hierarchy, ownership, optionality, urgency, accountability, deadline, disagreement, and commitment. Do not invent a greeting, subject line, apology, thanks, promise, approval, escalation, pressure, or extra softener. Avoid ceremonial wording, bureaucratic padding, and literal calques from the source language.
    """

    private static let peersPrompt = """
    Render the translation as relaxed peer-to-peer communication between equals. Express casualness only inside source-anchored units through target-language pronouns, contractions, particles, common vocabulary, and compact sentence rhythm when the source relationship permits them. Preserve the exact familiarity, teasing, disagreement, boundaries, directness, politeness intent, and emotional intensity. Interpret pronouns, omitted subjects, address forms, and interactional particles by pragmatic function rather than word-for-word form. When a particle softens a proposal, seeks alignment, invites agreement, or frames shared action, express that function naturally in the target language; never turn a shared suggestion into a unilateral promise or vice versa. Preserve the opening speech act and its position exactly: the translation's first semantic unit must correspond to the source's first semantic unit. If the source starts with a question, request, or statement, start with that same act; do not place a salutation, interjection, vocative, acknowledgment, or filler before it. Do not introduce a standalone social opener or closer absent from the source. Casual tone must never be created by adding a new discourse unit. Before returning, align every target unit to the source and remove any unanchored social framing. Avoid canned friendliness and do not add slang, memes, jokes, emojis, flirtation, intimacy, swearing, pet names, or exaggerated enthusiasm unless clearly present in the source.
    """

    static let defaults: [StylePreset] = [
        StylePreset(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            name: "Giao tiếp tự nhiên",
            prompt: naturalConversationPrompt,
            symbol: "bubble.left.and.bubble.right.fill",
            isFavorite: true,
            builtIn: .naturalConversation
        ),
        StylePreset(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            name: "Học thuật",
            prompt: academicPrompt,
            symbol: "graduationcap.fill",
            isFavorite: true,
            builtIn: .academic
        ),
        StylePreset(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
            name: "Công việc",
            prompt: professionalPrompt,
            symbol: "briefcase.fill",
            isFavorite: true,
            builtIn: .professional
        ),
        StylePreset(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
            name: "Bạn bè cùng lứa",
            prompt: peersPrompt,
            symbol: "person.2.fill",
            isFavorite: true,
            builtIn: .peers
        )
    ]

    static func defaultPreset(for kind: BuiltInStylePreset) -> StylePreset {
        defaults.first { $0.builtIn == kind }!
    }

    static func upgradeLegacyBuiltInPrompts(_ presets: [StylePreset]) -> [StylePreset] {
        let knownLegacyPrompts: [BuiltInStylePreset: Set<String>] = [
            .naturalConversation: [
                "Use the wording a native speaker would choose in ordinary one-to-one conversation. Prefer clear, idiomatic sentences and natural rhythm; use contractions or their target-language equivalent only when they are normal for the relationship. Remove translationese and source-language word order, but do not make the message more casual, warmer, colder, more direct, or more polite than the source. Keep greetings, address terms, requests, disagreement, hesitation, emotional intensity, and implied distance at the same level. Never introduce slang, jokes, emojis, pet names, or cultural references that are not present."
            ],
            .academic: [
                "First infer the academic domain from the source itself: for example mathematics, physics, engineering, computing, medicine, life sciences, law, economics, business, education, social sciences, humanities, or interdisciplinary research. Then use the established target-language terminology and conventions of that domain. If the field is ambiguous, keep the terminology neutral and preserve the original term rather than guessing. Write formal academic prose appropriate for a paper, thesis, research note, textbook, lecture material, or scholarly discussion. Preserve the source's evidential strength exactly: never turn a possibility into a conclusion, correlation into causation, observation into proof, or a tentative claim into a stronger claim. Retain technical terms, definitions, symbols, formulas, variables, units, citations, quotations, methodology, qualifications, modality, limitations, and logical scope exactly. Use precise logical links and an objective register. Avoid contractions, conversational fillers, rhetorical flourish, vague intensifiers, simplification, and unsupported explanation. Never invent references, terminology, data, or disciplinary context.",
                "Use formal academic prose appropriate for a paper, thesis, research note, or scholarly discussion. Prefer precise established terminology, explicit logical links, disciplined syntax, and an objective register. Preserve the source's evidential strength exactly: do not turn a possibility into a conclusion, a correlation into causation, or a tentative claim into a stronger one. Retain technical terms, definitions, variables, citations, quotations, qualifications, modality, and limitations exactly. Avoid contractions, conversational fillers, rhetorical flourish, vague intensifiers, and unsupported explanation. Do not invent references or normalize terminology that may be domain-specific."
            ],
            .professional: [
                "Use concise, polished workplace language suitable for a colleague, manager, client, or partner, while matching the relationship implied by the source. Make requests actionable and courteous without becoming ceremonial, vague, or overly deferential. In English, prefer native business phrasing such as 'Are you available?' or 'I'd like to ask for your help' only when it accurately matches the source; in every other language, use the equivalent native register rather than literal English patterns. Preserve hierarchy, ownership, deadlines, urgency, accountability, commitment, disagreement, and level of politeness exactly. Do not add apologies, promises, thanks, softeners, pressure, or urgency that the source did not express.",
                "Use clear, polished, courteous workplace language. Prefer professional but natural expressions such as 'Are you available?' and 'I'd like to ask for your help' instead of casual or excessively formal wording. Preserve the original request strength, urgency, hierarchy, and level of politeness."
            ],
            .peers: [
                "Render the translation as relaxed peer-to-peer communication between equals. Express casualness only inside source-anchored units through target-language pronouns, contractions, particles, common vocabulary, and compact sentence rhythm when the source relationship permits them. Preserve the exact familiarity, teasing, disagreement, boundaries, directness, politeness intent, and emotional intensity. Preserve the opening speech act and its position exactly: the translation's first semantic unit must correspond to the source's first semantic unit. If the source starts with a question, request, or statement, start with that same act; do not place a salutation, interjection, vocative, acknowledgment, or filler before it. Do not introduce a standalone social opener or closer absent from the source. Casual tone must never be created by adding a new discourse unit. Before returning, align every target unit to the source and remove any unanchored social framing. Avoid canned friendliness and do not add slang, memes, jokes, emojis, flirtation, intimacy, swearing, pet names, or exaggerated enthusiasm unless clearly present in the source.",
                "Render the translation as relaxed peer-to-peer communication between equals. Use casual target-language pronouns, contractions, particles, common vocabulary, and compact sentence rhythm only when the source relationship and the target language permit them. Preserve the exact familiarity, teasing, disagreement, boundaries, directness, politeness intent, and emotional intensity. If the source contains a greeting, translate its social function naturally at the same familiarity; if it contains none, begin directly without fabricating an opener. Avoid canned friendliness and repetitive greeting formulas. Do not add slang, memes, jokes, emojis, flirtation, intimacy, swearing, pet names, or exaggerated enthusiasm unless they are clearly present in the source.",
                "Use relaxed, warm peer-to-peer language between friends or people of similar age. Choose the target language's natural casual register and prefer short, everyday phrasing or contractions only when normal for that language. Preserve greetings exactly in function: if the source has no greeting, do not add any greeting; if it has a greeting, render only a natural equivalent at the same level of familiarity. Never insert or replace a greeting with 'Hey', 'Hi', 'Hello', or any other greeting merely to make the text sound casual. Preserve the original familiarity, teasing, disagreement, boundaries, politeness, emotional intensity, and directness exactly. Do not add slang, memes, jokes, emojis, flirtation, intimacy, swearing, exaggerated enthusiasm, or informal pronouns unless the source clearly contains them.",
                "Use relaxed, warm peer-to-peer language between friends or people of similar age. Choose the target language's natural casual register; for English, use 'Hi' or 'Hey' rather than 'Hello' only when the source itself is casual, and use equivalent native greetings in other languages. Prefer short, everyday phrasing and contractions or their native equivalent where normal. Preserve the original familiarity, teasing, disagreement, boundaries, politeness, and emotion exactly. Do not add slang, memes, jokes, emojis, flirtation, intimacy, swearing, exaggerated enthusiasm, or informal pronouns unless the source clearly contains them.",
                "Use relaxed, warm peer-to-peer language that friends of a similar age would naturally use. For casual greetings, prefer 'Hi' or 'Hey' over 'Hello' when appropriate. Use contractions and everyday phrasing, but do not add slang, jokes, intimacy, emojis, or emotional intensity that is absent from the source."
            ]
        ]
        return presets.map { preset in
            guard let kind = preset.builtIn else { return preset }
            if knownLegacyPrompts[kind]?.contains(preset.prompt) == true {
                var upgraded = preset
                upgraded.prompt = defaultPreset(for: kind).prompt
                return upgraded
            }
            return preset
        }
    }
}

enum TranslationLanguageGuard {
    static func accepts(_ text: String, target: AppLanguage) -> Bool {
        guard target != .automatic else { return true }
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        guard letters >= 4 else { return true }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let detected = recognizer.dominantLanguage else { return true }
        let code = detected.rawValue.lowercased()

        switch target {
        case .automatic: return true
        case .vietnamese: return code == "vi" || code.hasPrefix("vi-")
        case .english: return code == "en" || code.hasPrefix("en-")
        case .japanese: return code == "ja" || code.hasPrefix("ja-")
        case .korean: return code == "ko" || code.hasPrefix("ko-")
        case .simplifiedChinese: return code == "zh-hans" || code == "zh"
        case .traditionalChinese: return code == "zh-hant" || code == "zh"
        case .french: return code == "fr" || code.hasPrefix("fr-")
        case .german: return code == "de" || code.hasPrefix("de-")
        case .spanish: return code == "es" || code.hasPrefix("es-")
        case .russian: return code == "ru" || code.hasPrefix("ru-")
        case .thai: return code == "th" || code.hasPrefix("th-")
        case .indonesian: return code == "id" || code.hasPrefix("id-")
        }
    }
}

struct StylePromptTemplate: Identifiable {
    let id: String
    let name: String
    let summary: String
    let symbol: String
    let prompt: String

    static let library: [StylePromptTemplate] = [
        .init(
            id: "friendly-chat",
            name: "Trò chuyện thân thiện",
            summary: "Ấm áp vừa đủ cho người quen; không tự dựng lời chào hay thân mật.",
            symbol: "bubble.left.and.bubble.right.fill",
            prompt: "Use warm, natural conversation suitable for people who know each other. Infer the medium and relationship only from the source; otherwise use a neutral friendly register. Prefer native collocations, concise sentences, and conversational rhythm. Surface warmth may be expressed through normal target-language wording, but preserve the original request force, social distance, boundaries, emotion, and certainty. Do not fabricate a greeting, intimacy, slang, humor, emojis, or enthusiasm."
        ),
        .init(
            id: "work-chat",
            name: "Tin nhắn công việc",
            summary: "Ngắn, rõ và lịch sự cho chat nội bộ; không biến đề nghị thành mệnh lệnh.",
            symbol: "briefcase.fill",
            prompt: "Use concise, courteous target-language workplace phrasing for internal chat or short team messages. Put the action, owner, decision, deadline, or question in a clear order only when those elements exist in the source. Use normal collegial surface courtesy without becoming ceremonial. Preserve hierarchy, request versus instruction, responsibility, urgency, uncertainty, disagreement, and commitment; do not add a greeting, apology, thanks, promise, escalation, or pressure."
        ),
        .init(
            id: "business-email",
            name: "Email đối tác",
            summary: "Email đối ngoại mạch lạc, nhã nhặn; không tự thêm cam kết hoặc xin lỗi.",
            symbol: "envelope.fill",
            prompt: "Use polished external business-email language suitable for a client, supplier, or partner. Follow target-language conventions for complete sentences, tactful requests, paragraph flow, and professional closings only when the corresponding function exists in the source. Preserve authority, optionality, dates, conditions, commercial commitments, certainty, and urgency. Do not invent a subject line, greeting, closing, apology, thanks, promise, guarantee, or follow-up action."
        ),
        .init(
            id: "academic-paper",
            name: "Bài viết học thuật",
            summary: "Tự nhận diện ngành/thể loại, dùng đúng thuật ngữ và mức độ bằng chứng.",
            symbol: "graduationcap.fill",
            prompt: "Infer the academic discipline and genre only from evidence in the source, then use established target-language terminology and conventions for that discipline. If ambiguous, remain technically neutral instead of guessing. Use disciplined syntax, objective register, and explicit logical wording only where the source already expresses that relation. Preserve definitions, formulas, variables, citations, quantifier scope, methodology, hedging, evidential strength, and limitations. Never invent a reference, explanation, claim, or disciplinary context."
        ),
        .init(
            id: "technical-docs",
            name: "Tài liệu kỹ thuật",
            summary: "Nhất quán thuật ngữ và cấu trúc thao tác; không tự thêm bước xử lý.",
            symbol: "text.book.closed.fill",
            prompt: "Use concise target-language technical-documentation conventions. Infer whether the source is a procedure, reference, warning, specification, or explanation, and preserve that document type. Keep code, identifiers, commands, flags, paths, formulas, units, placeholders, prerequisites, warnings, ordered steps, and cross-references intact. Use one established equivalent consistently for each technical concept. Never add a step, fix, warning, cause, recommendation, or explanation absent from the source."
        ),
        .init(
            id: "customer-care",
            name: "Chăm sóc khách hàng",
            summary: "Bình tĩnh, tôn trọng và có hướng xử lý; không tự xin lỗi hay hứa bồi thường.",
            symbol: "heart.text.square.fill",
            prompt: "Use calm, respectful target-language customer-support wording. Keep the issue, acknowledged impact, available action, policy, condition, limitation, timeline, and commitment exactly as stated. Organize existing resolution steps clearly, but do not invent diagnosis or troubleshooting. Surface empathy may be expressed only to the degree supported by the source. Do not add an apology, blame, guarantee, refund, compensation, exception, promise, or escalation."
        )
    ]
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: L10n.string("Theo hệ thống")
        case .light: L10n.string("Sáng")
        case .dark: L10n.string("Tối")
        }
    }
}

struct LanguagePair: Codable, Identifiable, Equatable {
    var id: UUID
    var source: AppLanguage
    var target: AppLanguage

    init(id: UUID = UUID(), source: AppLanguage, target: AppLanguage) {
        self.id = id
        self.source = source
        self.target = target == .automatic ? .vietnamese : target
    }

    var title: String {
        let sourceName = source == .automatic ? L10n.string("Tự động") : source.title.replacingOccurrences(of: "Tiếng ", with: "")
        let targetName = target.title.replacingOccurrences(of: "Tiếng ", with: "")
        return "\(sourceName) → \(targetName)"
    }
}

struct GlobalShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let openWindow = GlobalShortcut(keyCode: 49, modifiers: 0x0100 | 0x0200) // ⌘⇧Space
    static let quickTranslate = GlobalShortcut(keyCode: 17, modifiers: 0x0100 | 0x0200) // ⌘⇧T
    static let replaceTranslate = GlobalShortcut(keyCode: 15, modifiers: 0x0100 | 0x0200) // ⌘⇧R

    var displayName: String {
        var value = ""
        if modifiers & 0x1000 != 0 { value += "⌃" }
        if modifiers & 0x0800 != 0 { value += "⌥" }
        if modifiers & 0x0200 != 0 { value += "⇧" }
        if modifiers & 0x0100 != 0 { value += "⌘" }
        value += Self.keyName(keyCode)
        return value
    }

    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if modifiers & 0x1000 != 0 { result |= 1 << 12 } // controlKey
        if modifiers & 0x0800 != 0 { result |= 1 << 11 } // optionKey
        if modifiers & 0x0200 != 0 { result |= 1 << 9 }  // shiftKey
        if modifiers & 0x0100 != 0 { result |= 1 << 8 }  // cmdKey
        return result
    }

    var menuModifierFlags: NSEvent.ModifierFlags {
        var result: NSEvent.ModifierFlags = []
        if modifiers & 0x1000 != 0 { result.insert(.control) }
        if modifiers & 0x0800 != 0 { result.insert(.option) }
        if modifiers & 0x0200 != 0 { result.insert(.shift) }
        if modifiers & 0x0100 != 0 { result.insert(.command) }
        return result
    }

    var menuKeyEquivalent: String {
        let values: [UInt32: String] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
            11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l", 38: "j",
            39: "'", 40: "k", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "n", 46: "m", 47: ".",
            49: " ", 36: "\r", 48: "\t", 51: "\u{8}"
        ]
        return values[keyCode] ?? ""
    }

    private static func keyName(_ code: UInt32) -> String {
        let names: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
            39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            49: "Space", 36: "Return", 48: "Tab", 51: "Delete", 53: "Esc",
            123: "←", 124: "→", 125: "↓", 126: "↑", 115: "Home", 119: "End",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7",
            100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        return names[code] ?? "Phím \(code)"
    }
}

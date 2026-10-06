import Foundation

enum GroqService {
    private static let endpoint = URL(
        string: "https://api.groq.com/openai/v1/chat/completions"
    )!
    private static let requestPacer = GroqRequestPacer()

    static func translate(
        text: String,
        source: AppLanguage,
        target: AppLanguage,
        model: GroqModel,
        apiKey: String
    ) async throws -> String {
        let prompt = TranslationPromptFactory.quickTranslation(
            text: text, source: source, target: target
        )
        let result = try await completeJSON(
            system: prompt.system,
            user: prompt.user,
            expectedOutputCharacters: text.count,
            model: model,
            apiKey: apiKey
        )
        return try validated(result, target: target)
    }

    /// A single structured request replaces the old translate → restyle → verify
    /// chain. It returns the comparable faithful draft and the final styled
    /// translation, reducing quota use and latency while retaining an explicit
    /// semantic check in the model instructions.
    static func translateWithStyle(
        text: String,
        source: AppLanguage,
        target: AppLanguage,
        preset: StylePreset,
        context: TranslationRequestContext,
        model: GroqModel,
        apiKey: String
    ) async throws -> StyledTranslationResult {
        let prompt = TranslationPromptFactory.styledTranslation(
            text: text, source: source, target: target, preset: preset, context: context
        )
        let output = try await completeJSONObject(
            system: prompt.system,
            user: prompt.user,
            expectedOutputCharacters: text.count * 2,
            model: model,
            apiKey: apiKey
        )
        guard let base = output["base_translation"] as? String,
              let translation = output["translation"] as? String else {
            throw TranslationServiceError.badResponse
        }
        let validatedBase = try validated(base, target: target)
        let validatedCandidate = try validated(translation, target: target)
        return StyledTranslationResult(
            baseTranslation: validatedBase,
            translation: StyledTranslationOutputGuard.sanitized(
                source: text,
                base: validatedBase,
                candidate: validatedCandidate,
                target: target
            )
        )
    }

    private static func completeJSON(
        system: String,
        user: String,
        expectedOutputCharacters: Int,
        model: GroqModel,
        apiKey: String
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw TranslationServiceError.missingKey("Groq") }

        let output = try await completeJSONObject(
            system: system,
            user: user,
            expectedOutputCharacters: expectedOutputCharacters,
            model: model,
            apiKey: apiKey
        )
        guard let translation = output["translation"] as? String else {
            throw TranslationServiceError.badResponse
        }
        return translation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func completeJSONObject(
        system: String,
        user: String,
        expectedOutputCharacters: Int,
        model: GroqModel,
        apiKey: String
    ) async throws -> [String: Any] {
        guard !apiKey.isEmpty else { throw TranslationServiceError.missingKey("Groq") }

        let completionTokens = GroqFreeTierPolicy.completionBudget(
            expectedOutputCharacters: expectedOutputCharacters,
            systemPrompt: system,
            userPrompt: user
        )
        let reservedTokens = GroqFreeTierPolicy.estimatedTokens(for: system)
            + GroqFreeTierPolicy.estimatedTokens(for: user)
            + completionTokens
        guard reservedTokens <= GroqFreeTierPolicy.safeRequestTokenBudget else {
            throw TranslationServiceError.server(
                413,
                "Nội dung và hướng dẫn đang vượt ngân sách an toàn của Groq Free. Hãy chia nội dung thành phần ngắn hơn."
            )
        }
        try await requestPacer.waitForTurn(reserving: reservedTokens)

        var body: [String: Any] = [
            "model": model.rawValue,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "reasoning_effort": model.reasoningEffort,
            "response_format": ["type": "json_object"],
            "temperature": 0.2,
            "max_completion_tokens": completionTokens,
            "stream": false
        ]
        if model.includesReasoningParameter {
            body["include_reasoning"] = false
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw TranslationServiceError.timedOut
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
                 .cannotConnectToHost, .dnsLookupFailed, .internationalRoamingOff:
                throw TranslationServiceError.networkUnavailable
            default:
                throw error
            }
        }

        guard let http = response as? HTTPURLResponse else {
            throw TranslationServiceError.badResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            switch http.statusCode {
            case 401, 403:
                throw TranslationServiceError.invalidKey("Groq")
            case 413:
                let message = errorMessage(from: data)
                if message.localizedCaseInsensitiveContains("tokens per minute") ||
                    message.localizedCaseInsensitiveContains("TPM") {
                    throw TranslationServiceError.quotaExceeded("Groq")
                }
                throw TranslationServiceError.server(
                    http.statusCode,
                    "Nội dung vượt giới hạn của model đã chọn."
                )
            case 429:
                throw TranslationServiceError.quotaExceeded("Groq")
            default:
                throw TranslationServiceError.server(
                    http.statusCode,
                    errorMessage(from: data)
                )
            }
        }

        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let output = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            throw TranslationServiceError.badResponse
        }
        return output
    }

    private static func validated(_ value: String, target: AppLanguage) throws -> String {
        guard !value.isEmpty else { throw TranslationServiceError.badResponse }
        guard TranslationLanguageGuard.accepts(value, target: target) else {
            throw TranslationServiceError.server(
                422,
                "Model trả về sai ngôn ngữ đích. Hãy thử lại hoặc chọn model khác."
            )
        }
        return value
    }

    private static func errorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String,
           !message.isEmpty {
            return message
        }
        return "Groq tạm thời không phản hồi."
    }
}

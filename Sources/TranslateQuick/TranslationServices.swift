import Foundation

enum TranslationServiceError: LocalizedError {
    case missingKey(String)
    case invalidKey(String)
    case quotaExceeded(String)
    case networkUnavailable
    case timedOut
    case fallbackFailed(String)
    case invalidEndpoint
    case badResponse
    case server(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingKey(let provider): "Chưa nhập API key cho \(provider) trong Cài đặt."
        case .invalidKey(let provider): "\(provider) API key không hợp lệ hoặc đã hết hiệu lực."
        case .quotaExceeded(let provider): "\(provider) đang hết hạn mức hoặc bị giới hạn tần suất. Hãy kiểm tra tài khoản rồi thử lại."
        case .networkUnavailable: "Không có kết nối mạng. Hãy kiểm tra Internet rồi thử lại."
        case .timedOut: "Kết nối dịch vụ quá lâu. Hãy thử lại sau."
        case .fallbackFailed(let message): message
        case .invalidEndpoint: "Địa chỉ API không hợp lệ."
        case .badResponse: "Dịch vụ trả về dữ liệu không hợp lệ."
        case .server(let status, let message): "Lỗi dịch vụ (\(status)): \(message)"
        }
    }
}

struct RemoteTranslationConfiguration {
    let provider: TranslationProvider
    let groqKey: String
    let groqModel: GroqModel
    let geminiKey: String
    let geminiModel: String
}

enum TranslationServices {
    static func translate(
        text: String,
        source: AppLanguage,
        target: AppLanguage,
        configuration: RemoteTranslationConfiguration
    ) async throws -> String {
        switch configuration.provider {
        case .groq:
            return try await GroqService.translate(
                text: text,
                source: source,
                target: target,
                model: configuration.groqModel,
                apiKey: configuration.groqKey
            )
        case .apple:
            throw TranslationServiceError.badResponse
        case .gemini:
            return try await gemini(text, source, target, configuration)
        }
    }

    private static func prompt(
        text: String,
        source: AppLanguage,
        target: AppLanguage
    ) -> String {
        let from = source == .automatic ? "the automatically detected language" : source.promptName
        return """
        Translate the text from \(from) into \(target.promptName). Preserve meaning, tone, names, line breaks, and formatting. Use fluent natural language. Return only the translation, without notes or quotation marks.

        <text>
        \(text)
        </text>
        """
    }

    private static func gemini(
        _ text: String,
        _ source: AppLanguage,
        _ target: AppLanguage,
        _ config: RemoteTranslationConfiguration
    ) async throws -> String {
        guard !config.geminiKey.isEmpty else { throw TranslationServiceError.missingKey("Gemini") }
        let model = config.geminiModel.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? config.geminiModel
        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")
        components?.queryItems = [URLQueryItem(name: "key", value: config.geminiKey)]
        guard let url = components?.url else { throw TranslationServiceError.invalidEndpoint }
        let body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": prompt(text: text, source: source, target: target)]]]],
            "generationConfig": ["temperature": 0.2]
        ]
        let data = try await request(url: url, headers: [:], body: body)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let result = parts.first?["text"] as? String else { throw TranslationServiceError.badResponse }
        return clean(result)
    }

    private static func request(url: URL, headers: [String: String], body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    private static func perform(_ request: URLRequest) async throws -> Data {
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
        guard let http = response as? HTTPURLResponse else { throw TranslationServiceError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw TranslationServiceError.invalidKey("API")
            }
            if http.statusCode == 429 {
                throw TranslationServiceError.quotaExceeded("Dịch vụ")
            }
            let message = serverMessage(from: data)
            throw TranslationServiceError.server(http.statusCode, message)
        }
        return data
    }

    private static func serverMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String,
           !message.isEmpty {
            return message
        }
        return "Dịch vụ tạm thời không phản hồi."
    }

    private static func clean(_ value: String) -> String {
        var result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("\"") && result.hasSuffix("\"") && result.count > 1 {
            result.removeFirst(); result.removeLast()
        }
        return result
    }
}

import Foundation
import FoundationModels

@main
struct FoundationModelSmoke {
    static func main() async {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            save("UNAVAILABLE: \(model.availability)")
            return
        }
        do {
            let session = LanguageModelSession(
                model: model,
                instructions: "Return only the exact word READY."
            )
            let response = try await session.respond(to: "Confirm that the local model can answer.")
            save(response.content.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            save("ERROR: \(String(reflecting: error))")
        }
    }

    private static func save(_ value: String) {
        try? value.write(
            to: URL(fileURLWithPath: "/private/tmp/translate-quick-fm-smoke-result.txt"),
            atomically: true,
            encoding: .utf8
        )
        print(value)
    }
}

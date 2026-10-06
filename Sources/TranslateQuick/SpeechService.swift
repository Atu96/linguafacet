import AVFoundation

@MainActor
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, language: AppLanguage) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        if language != .automatic { utterance.voice = AVSpeechSynthesisVoice(language: language.rawValue) }
        utterance.rate = 0.46
        synthesizer.speak(utterance)
    }
}

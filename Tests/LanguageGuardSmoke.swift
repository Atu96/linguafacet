import Foundation

@main
struct LanguageGuardSmoke {
    static func main() {
        let samples: [(AppLanguage, String)] = [
            (.vietnamese, "Xin chào, hôm nay bạn có rảnh để nói chuyện không?"),
            (.english, "Hello, are you available to talk today?"),
            (.japanese, "こんにちは。今日はお話しする時間がありますか。"),
            (.korean, "안녕하세요. 오늘 이야기할 시간이 있으신가요?"),
            (.simplifiedChinese, "你好，请问你今天有时间聊一聊吗？"),
            (.traditionalChinese, "你好，請問你今天有時間聊一聊嗎？"),
            (.french, "Bonjour, avez-vous le temps de discuter aujourd’hui ?"),
            (.german, "Hallo, haben Sie heute Zeit für ein Gespräch?"),
            (.spanish, "Hola, ¿tienes tiempo para hablar hoy?"),
            (.russian, "Здравствуйте, у вас сегодня есть время поговорить?"),
            (.thai, "สวัสดี วันนี้คุณมีเวลาคุยกันไหม"),
            (.indonesian, "Halo, apakah Anda punya waktu untuk berbicara hari ini?")
        ]

        for (language, text) in samples {
            precondition(
                TranslationLanguageGuard.accepts(text, target: language),
                "Expected \(language.rawValue) sample to be accepted"
            )
        }
        precondition(
            !TranslationLanguageGuard.accepts(samples[1].1, target: .vietnamese),
            "English output must be rejected when Vietnamese is requested"
        )
        precondition(
            !TranslationLanguageGuard.accepts(samples[0].1, target: .english),
            "Vietnamese output must be rejected when English is requested"
        )
        print("Language guard passed \(samples.count) target languages plus mismatch checks.")
    }
}

import SwiftUI

struct QuickPanelView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.16))
                    Image(systemName: settings.provider.symbol).foregroundStyle(.blue)
                }
                .frame(width: 28, height: 28)
                Text(settings.provider.title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(settings.quickTargetLanguage.title).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("VĂN BẢN GỐC").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text(model.sourceText).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 7) {
                        Text("BẢN DỊCH").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        if model.isTranslating {
                            HStack { ProgressView().controlSize(.small); Text("Đang dịch…").foregroundStyle(.secondary) }
                        } else if !model.errorMessage.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(model.errorMessage, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                                Button("Thử lại", action: model.retry)
                                    .buttonStyle(.glassProminent)
                                    .controlSize(.small)
                            }
                        } else {
                            Text(model.translatedText).font(.system(size: 15, weight: .medium)).textSelection(.enabled)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack(spacing: 8) {
                Button { model.openInMainWindow() } label: { Label("Mở cửa sổ", systemImage: "macwindow") }
                    .buttonStyle(.glass)
                Spacer()
                Button { model.speakResult() } label: { Image(systemName: "speaker.wave.2") }
                    .buttonStyle(.glass)
                    .disabled(model.translatedText.isEmpty)
                Button { model.copyResult() } label: { Label("Sao chép", systemImage: "doc.on.doc") }
                    .buttonStyle(.glass)
                    .disabled(model.translatedText.isEmpty)
                Button { model.replaceWithResult() } label: { Label("Thay thế", systemImage: "arrow.uturn.right") }
                    .buttonStyle(.glassProminent)
                    .disabled(model.translatedText.isEmpty)
            }
            .padding(12)
        }
        .frame(width: 470, height: 330)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .padding(1)
        .translationTask(model.mode == .manual ? nil : model.configuration) { session in
            await model.translate(using: session)
        }
    }
}

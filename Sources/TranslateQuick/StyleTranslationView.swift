import AppKit
import SwiftUI

struct StyleTranslationView: View {
    @ObservedObject var model: StyleTranslationModel
    @ObservedObject var settings: SettingsStore
    @State private var availableWidth: CGFloat = 1120
    @State private var availableHeight: CGFloat = TQLayout.mainWindowMinHeight

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ambientBackground
                VStack(spacing: TQLayout.dense) {
                    controls
                    editors
                    if !model.baseTranslation.isEmpty { baseComparison }
                    footer
                }
                .padding(TQLayout.standard)
            }
            .onAppear {
                availableWidth = proxy.size.width
                availableHeight = proxy.size.height
                reportPreferredHeight(compact: proxy.size.width < TQLayout.compactBreakpoint)
            }
            .onChange(of: proxy.size.width) {
                availableWidth = proxy.size.width
                reportPreferredHeight(compact: proxy.size.width < TQLayout.compactBreakpoint)
            }
            .onChange(of: proxy.size.height) { availableHeight = proxy.size.height }
        }
        .frame(minWidth: 620)
        .translationTask(model.configuration) { session in
            await model.translate(using: session)
        }
        .onAppear { reportPreferredHeight() }
        .onChange(of: model.sourceText) { reportPreferredHeight() }
        .onChange(of: model.baseTranslation) { reportPreferredHeight() }
        .onChange(of: model.styledTranslation) { reportPreferredHeight() }
        .onChange(of: model.selectedPresetID) { reportPreferredHeight() }
        .onChange(of: settings.stylePresets) {
            if !settings.stylePresets.contains(where: { $0.id == model.selectedPresetID }),
               let fallback = settings.favoriteStylePresets.first ?? settings.stylePresets.first {
                model.selectPreset(fallback.id)
            }
            reportPreferredHeight()
        }
        .onChange(of: model.showBaseTranslation) { reportPreferredHeight() }
        .onChange(of: settings.provider) { reportPreferredHeight() }
        .onChange(of: settings.groqStyleModel) { reportPreferredHeight() }
        .onChange(of: settings.styleSourceLanguage) { model.languageSelectionDidChange() }
        .onChange(of: settings.styleTargetLanguage) { model.languageSelectionDidChange() }
    }

    private var ambientBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(
                colors: [Color.purple.opacity(0.12), Color.clear, Color.blue.opacity(0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle().fill(Color.purple.opacity(0.10)).frame(width: 380, height: 380)
                .blur(radius: 90).offset(x: 360, y: -260)
            Circle().fill(Color.cyan.opacity(0.08)).frame(width: 320, height: 320)
                .blur(radius: 80).offset(x: -360, y: 260)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var controls: some View {
        VStack(spacing: 11) {
            HStack(spacing: 10) {
                Picker("Nguồn", selection: $settings.styleSourceLanguage) {
                    ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden().frame(maxWidth: .infinity)
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                Picker("Đích", selection: $settings.styleTargetLanguage) {
                    ForEach(AppLanguage.allCases.filter { $0 != .automatic }) { Text($0.title).tag($0) }
                }
                .labelsHidden().frame(maxWidth: .infinity)
            }

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(settings.favoriteStylePresets) { preset in
                            Button {
                                model.selectPreset(preset.id)
                            } label: {
                                Label(preset.name, systemImage: preset.symbol)
                                    .lineLimit(1)
                            }
                            .buttonStyle(.glass(model.selectedPresetID == preset.id ? .regular.tint(.purple) : .regular))
                            .controlSize(.small)
                            .frame(height: TQLayout.controlTarget)
                            .disabled(settings.stylePresetValidationMessage(for: preset.id) != nil)
                        }
                    }
                }
                TranslationContextControl(
                    context: $model.translationContext,
                    protectedTermsText: $settings.protectedTermsText
                )
                Button {
                    model.onRequestStyleSettings?()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.glass)
                .controlSize(.small)
                .frame(width: TQLayout.controlTarget, height: TQLayout.controlTarget)
                .help("Quản lý preset văn phong")
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: TQLayout.cardRadius))
    }

    @ViewBuilder
    private var editors: some View {
        if isCompactLayout {
            VStack(spacing: 12) {
                sourceEditor
                resultEditor
            }
            .padding(.horizontal, 2)
            .frame(height: compactEditorHeight * 2 + 12)
        } else {
            HStack(spacing: 14) {
                sourceEditor
                resultEditor
            }
            .padding(.horizontal, 2)
            .frame(height: editorHeight)
        }
    }

    private var sourceEditor: some View {
        EditorCard(
                title: "Nội dung gốc",
                text: $model.sourceText,
                placeholder: "Nhập hoặc dán nội dung cần dịch…",
                characterCount: model.sourceText.count,
                isResult: false,
                onPaste: model.pasteSource,
                onCopy: nil,
                onClear: model.clear,
                onSpeak: model.speakSource,
                focusOnAppear: true
            )
    }

    private var resultEditor: some View {
        EditorCard(
                title: "Bản dịch · \(model.selectedPresetTitle)",
                text: $model.styledTranslation,
                placeholder: model.isWorking ? model.status : "Kết quả đã chỉnh văn phong sẽ xuất hiện ở đây",
                characterCount: model.styledTranslation.count,
                isResult: true,
                onPaste: nil,
                onCopy: model.copyResult,
                onClear: { model.styledTranslation = "" },
                onSpeak: model.speakResult
            )
    }

    private var isCompactLayout: Bool { availableWidth < TQLayout.compactBreakpoint }

    private var compactEditorHeight: CGFloat {
        max(165, (availableHeight - styleChromeHeight) / 2)
    }

    private var desiredCompactEditorHeight: CGFloat {
        let longest = max(measuredHeight(model.sourceText), measuredHeight(model.styledTranslation))
        return max(165, longest + 70)
    }

    private var baseComparison: some View {
        DisclosureGroup(isExpanded: $model.showBaseTranslation) {
            ScrollView(.vertical) {
                Text(model.baseTranslation)
                    .font(.callout).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
            .frame(maxHeight: 110)
        } label: {
            Label("Đối chiếu bản dịch nền chưa chỉnh văn phong", systemImage: "checkmark.shield")
                .font(.caption.weight(.semibold))
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var footer: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if !model.errorMessage.isEmpty {
                    Label(model.errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red).lineLimit(2)
                } else {
                    Text(model.status).foregroundStyle(.secondary)
                }
                Text("Kết quả được kiểm tra hai lượt nhưng vẫn nên đối chiếu bản dịch nền khi nội dung quan trọng.")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .font(.caption)

            Spacer()
            if model.isWorking { Button("Hủy", action: model.cancel).buttonStyle(.glass) }
            Button(action: model.translateWithStyle) {
                HStack(spacing: 8) {
                    if model.isWorking { ProgressView().controlSize(.small) }
                    Label("Dịch theo văn phong", systemImage: "wand.and.sparkles")
                }
            }
            .buttonStyle(.glassProminent)
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(model.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isWorking || !model.isModelAvailable)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private var editorHeight: CGFloat {
        max(200, availableHeight - styleChromeHeight)
    }

    private var desiredEditorHeight: CGFloat {
        let longest = max(
            measuredHeight(model.sourceText),
            measuredHeight(model.styledTranslation)
        )
        return max(200, longest + 91)
    }

    private var styleChromeHeight: CGFloat {
        if model.baseTranslation.isEmpty { return 245 }
        return model.showBaseTranslation ? 390 : 303
    }

    private func measuredHeight(_ text: String) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let systemFont = NSFont.systemFont(ofSize: 16)
        let descriptor = systemFont.fontDescriptor.withDesign(.rounded) ?? systemFont.fontDescriptor
        let font = NSFont(descriptor: descriptor, size: 16) ?? systemFont
        let rect = (text as NSString).boundingRect(
            with: NSSize(width: isCompactLayout ? 560 : 455, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return ceil(rect.height) + 20
    }

    private func reportPreferredHeight(compact: Bool? = nil) {
        let compact = compact ?? isCompactLayout
        let comparisonHeight: CGFloat
        if model.baseTranslation.isEmpty {
            comparisonHeight = 0
        } else {
            comparisonHeight = model.showBaseTranslation ? 145 : 58
        }
        let contentHeight = compact ? desiredCompactEditorHeight * 2 + 12 : desiredEditorHeight
        model.onPreferredWindowHeight?(
            max(compact ? 640 : TQLayout.mainWindowMinHeight, contentHeight + 290 + comparisonHeight)
        )
    }
}

import AppKit
import SwiftUI

struct MainView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: SettingsStore
    @State private var availableWidth: CGFloat = 1120
    @State private var availableHeight: CGFloat = TQLayout.mainWindowMinHeight

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ambientBackground
                VStack(spacing: TQLayout.dense) {
                    languageBar
                    editors
                    translationStatus
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
        .translationTask(model.mode == .manual ? model.configuration : nil) { session in
            await model.translate(using: session)
        }
        .onAppear { reportPreferredHeight() }
        .onChange(of: model.sourceText) {
            model.scheduleAutoTranslation()
            reportPreferredHeight()
        }
        .onChange(of: model.translatedText) { reportPreferredHeight() }
        .onChange(of: settings.quickSourceLanguage) { model.scheduleAutoTranslation() }
        .onChange(of: settings.quickTargetLanguage) { model.scheduleAutoTranslation() }
        .onChange(of: settings.provider) {
            model.scheduleAutoTranslation()
            reportPreferredHeight()
        }
        .onChange(of: settings.groqTranslationModel) {
            model.scheduleAutoTranslation()
            reportPreferredHeight()
        }
    }

    private var ambientBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(
                colors: [Color.blue.opacity(0.12), Color.clear, Color.purple.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.cyan.opacity(0.10))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -340, y: -250)
            Circle()
                .fill(Color.indigo.opacity(0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 390, y: 260)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var languageBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Picker("Ngôn ngữ nguồn", selection: $settings.quickSourceLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Button(action: model.swapLanguages) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.glass)
                .frame(height: TQLayout.controlTarget)
                .help("Đảo ngôn ngữ")

                Picker("Ngôn ngữ đích", selection: $settings.quickTargetLanguage) {
                    ForEach(AppLanguage.allCases.filter { $0 != .automatic }) { language in
                        Text(language.title).tag(language)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            if !settings.favoritePairs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(settings.favoritePairs) { pair in
                            let selected = pair.source == settings.quickSourceLanguage &&
                                pair.target == settings.quickTargetLanguage
                            Button(pair.title) { settings.applyPair(pair, to: .quickTranslate) }
                                .buttonStyle(.glass(selected ? .regular.tint(.blue) : .regular))
                                .controlSize(.small)
                                .frame(height: TQLayout.controlTarget)
                                .accessibilityValue(selected ? "Đang chọn" : "")
                                .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: TQLayout.cardRadius))
    }

    private var translationStatus: some View {
        HStack(spacing: 8) {
            Group {
                if !model.errorMessage.isEmpty {
                    Label(model.errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Label(
                        model.status,
                        systemImage: model.isTranslating ? "arrow.trianglehead.2.clockwise.rotate.90" : "checkmark.circle"
                    )
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .layoutPriority(2)

            if availableWidth >= 940, !model.detectedLanguage.isEmpty {
                Divider().frame(height: 14)
                Label("Nguồn: \(model.detectedLanguage)", systemImage: "waveform.badge.magnifyingglass")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            Spacer(minLength: 12)

            Group {
                if model.isTranslating {
                    Button("Hủy", action: model.cancel)
                        .buttonStyle(.glass)
                        .controlSize(.small)
                } else if !model.errorMessage.isEmpty {
                    Button("Thử lại", action: model.retry)
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
            }
            .fixedSize()

            Button("Dịch ngay", action: model.translateManual)
                .keyboardShortcut(.return, modifiers: [.command])
                .labelsHidden()
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
                .disabled(model.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isTranslating)
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .center)
        .layoutPriority(2)
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
                title: "Văn bản gốc",
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
                title: "Bản dịch",
                text: $model.translatedText,
                placeholder: model.isTranslating ? "Đang dịch…" : "Bản dịch sẽ xuất hiện ở đây",
                characterCount: model.translatedText.count,
                isResult: true,
                onPaste: nil,
                onCopy: model.copyResult,
                onClear: { model.translatedText = "" },
                onSpeak: model.speakResult
            )
    }

    private var isCompactLayout: Bool { availableWidth < TQLayout.compactBreakpoint }

    private var compactEditorHeight: CGFloat {
        max(170, (availableHeight - 205) / 2)
    }

    private var desiredCompactEditorHeight: CGFloat {
        let longest = max(measuredHeight(model.sourceText), measuredHeight(model.translatedText))
        return max(170, longest + 72)
    }

    private var editorHeight: CGFloat {
        max(210, availableHeight - 185)
    }

    private var desiredEditorHeight: CGFloat {
        let longest = max(measuredHeight(model.sourceText), measuredHeight(model.translatedText))
        return max(210, longest + 91)
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
        let chromeHeight: CGFloat = settings.favoritePairs.isEmpty ? 177 : 237
        let contentHeight = compact ? desiredCompactEditorHeight * 2 + 12 : desiredEditorHeight
        model.onPreferredWindowHeight?(
            max(compact ? 640 : TQLayout.mainWindowMinHeight, contentHeight + chromeHeight)
        )
    }
}

struct EditorCard: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let characterCount: Int
    let isResult: Bool
    let onPaste: (() -> Void)?
    let onCopy: (() -> Void)?
    let onClear: () -> Void
    let onSpeak: () -> Void
    var focusOnAppear = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(characterCount) ký tự").font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 16, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                FocusedTextEditor(
                    text: $text,
                    focusOnAppear: focusOnAppear,
                    accessibilityLabel: isResult ? "Bản dịch" : "Văn bản gốc"
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack(spacing: 4) {
                if let onPaste {
                    Button(action: onPaste) { Label("Dán", systemImage: "doc.on.clipboard") }
                        .buttonStyle(.borderless)
                        .frame(width: 56, height: TQLayout.controlTarget)
                }
                if let onCopy {
                    Button(action: onCopy) { Label("Sao chép", systemImage: "doc.on.doc") }
                        .buttonStyle(.borderless)
                        .frame(width: 84, height: TQLayout.controlTarget)
                }
                Spacer()
                Button(action: onSpeak) {
                    Image(systemName: "speaker.wave.2")
                }
                .buttonStyle(.borderless)
                .frame(width: TQLayout.controlTarget, height: TQLayout.controlTarget)
                .contentShape(Rectangle())
                .help("Đọc thành tiếng")
                .accessibilityLabel("Đọc thành tiếng")
                Button(action: onClear) {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .frame(width: TQLayout.controlTarget, height: TQLayout.controlTarget)
                .contentShape(Rectangle())
                .help("Xóa nội dung")
                .accessibilityLabel("Xóa nội dung")
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TQLayout.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: TQLayout.cardRadius).stroke(Color.white.opacity(0.14)))
        .shadow(color: .black.opacity(0.07), radius: 18, y: 8)
    }
}

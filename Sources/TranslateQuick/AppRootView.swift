import FoundationModels
import SwiftUI

struct AppRootView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var styleModel: StyleTranslationModel
    @ObservedObject var settings: SettingsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var supportHovered = false
    @State private var settingsHovered = false

    var body: some View {
        VStack(spacing: 0) {
            tabBar
                .zIndex(10)
            Group {
                switch model.selectedModule {
                case .quickTranslate:
                    MainView(model: model, settings: settings)
                case .writingStyle:
                    StyleTranslationView(model: styleModel, settings: settings)
                }
            }
            .zIndex(0)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .ignoresSafeArea(.container, edges: .top)
        .environment(\.locale, Locale(identifier: settings.interfaceLanguage.rawValue))
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            // Keep interactive content clear of the native macOS traffic lights
            // while allowing the old standalone title strip to disappear.
            Color.clear
                .frame(width: 112, height: 1)

            moduleTab(.quickTranslate, tint: .blue)
            moduleTab(.writingStyle, tint: .purple)

            Spacer(minLength: 18)

            Label(statusText, systemImage: statusReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(statusReady ? .green : .orange)
                .lineLimit(1)

            Button {
                if !settings.openSupportPage() {
                    settings.selectedSettingsTab = .about
                    model.onRequestSettings?()
                }
            } label: {
                Label("Ủng hộ", systemImage: "heart.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(supportHovered ? Color.red : Color.secondary)
                    .padding(.horizontal, 4)
                    .frame(height: TQLayout.controlTarget)
            }
            .buttonStyle(.plain)
            .fixedSize()
            .background {
                RoundedRectangle(cornerRadius: TQLayout.smallRadius)
                    .fill(Color.primary.opacity(supportHovered ? 0.09 : 0))
            }
            .contentShape(RoundedRectangle(cornerRadius: TQLayout.smallRadius))
            .onHover { supportHovered = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: supportHovered)
            .help("Ủng hộ LinguaFacet trên Ko-fi")
            .accessibilityLabel("Ủng hộ LinguaFacet trên Ko-fi")

            Button {
                model.onRequestSettings?()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(settingsHovered ? Color.primary : Color.secondary)
                    .frame(width: TQLayout.controlTarget, height: TQLayout.controlTarget)
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: TQLayout.smallRadius)
                    .fill(Color.primary.opacity(settingsHovered ? 0.09 : 0))
            }
            .contentShape(RoundedRectangle(cornerRadius: TQLayout.smallRadius))
            .onHover { settingsHovered = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: settingsHovered)
            .help("Cài đặt")
            .accessibilityLabel("Cài đặt")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func moduleTab(_ module: AppModule, tint: Color) -> some View {
        let selected = model.selectedModule == module
        return Button {
            model.selectedModule = module
        } label: {
            HStack(spacing: 8) {
                Image(systemName: module.symbol)
                    .font(.system(size: 14, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? tint : Color.secondary)
                Text(module.title)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
            }
            .padding(.horizontal, 14)
            .frame(height: TQLayout.tabHeight)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.regularMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.22)))
                        .shadow(color: .black.opacity(0.07), radius: 5, y: 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 132)
        .contentShape(Rectangle())
        .accessibilityLabel(module.title)
        .accessibilityValue(selected ? "Đang chọn" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .zIndex(2)
    }

    private var statusReady: Bool {
        if model.selectedModule == .writingStyle {
            if settings.provider == .groq {
                return settings.hasGroqKey
            }
            return SystemLanguageModel.default.isAvailable
        }
        switch settings.provider {
        case .groq: return settings.hasGroqKey
        case .apple: return true
        case .gemini: return settings.hasGeminiKey
        }
    }

    private var statusText: String {
        if model.selectedModule == .writingStyle { return styleModel.modelAvailabilityText }
        if settings.provider == .groq, !settings.hasGroqKey {
            return "Groq chưa có key · Apple dự phòng"
        }
        return statusReady ? settings.provider.title : "\(settings.provider.title) · thiếu API key"
    }
}

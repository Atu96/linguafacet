import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var accessibility: SelectionController
    @State private var selectedStylePresetID: UUID?
    @State private var showingPromptLibrary = false
    @State private var showingAdvancedPrompt = false

    init(settings: SettingsStore, accessibility: SelectionController) {
        self.settings = settings
        self.accessibility = accessibility
        _selectedStylePresetID = State(initialValue: settings.stylePresets.first?.id)
    }

    var body: some View {
        TabView(selection: $settings.selectedSettingsTab) {
            generalTab
                .tabItem { Label("Chung", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            languagesTab
                .tabItem { Label("Ngôn ngữ", systemImage: "character.book.closed") }
                .tag(SettingsTab.languages)
            stylesTab
                .tabItem { Label("Văn phong", systemImage: "textformat.alt") }
                .tag(SettingsTab.styles)
            serviceTab
                .tabItem { Label("Dịch vụ", systemImage: "network") }
                .tag(SettingsTab.services)
            shortcutsTab
                .tabItem { Label("Phím tắt", systemImage: "command") }
                .tag(SettingsTab.shortcuts)
            aboutTab
                .tabItem { Label("Giới thiệu", systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
        .padding(20)
        .frame(width: 780, height: 620)
        .environment(\.locale, Locale(identifier: settings.interfaceLanguage.rawValue))
        .sheet(isPresented: $showingPromptLibrary) {
            StylePromptLibraryView { template in
                guard let id = selectedStylePresetID else { return }
                settings.applyStyleTemplate(template, to: id)
                showingPromptLibrary = false
            }
        }
    }

    private var aboutTab: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("LinguaFacet")
                            .font(.title2.weight(.semibold))
                        Text("Phiên bản \(appVersion) · build \(appBuild)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Dịch đúng ý, đúng giọng điệu và ngữ cảnh trên macOS.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Ủng hộ hoàn toàn tự nguyện") {
                Text("Mình tạo những ứng dụng nhỏ, hữu ích và chia sẻ để mọi người sử dụng. Nếu LinguaFacet giúp bạn tiết kiệm thời gian, một chút ủng hộ trên Ko-fi sẽ tiếp thêm động lực để mình tiếp tục sửa lỗi và cải thiện ứng dụng. Hoàn toàn tùy bạn — cảm ơn bạn đã sử dụng! ❤️")
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    settings.openSupportPage()
                } label: {
                    Label("Ủng hộ trên Ko-fi", systemImage: "heart.fill")
                }
                .buttonStyle(.glass)
                .tint(.red)
                .accessibilityHint("Mở trang Ko-fi của tác giả trong trình duyệt")

                Text("Liên kết chỉ mở khi bạn bấm. Ứng dụng không gửi nội dung dịch, lịch sử sử dụng hay thông tin tài khoản tới Ko-fi.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !settings.supportMessage.isEmpty {
                    Label(settings.supportMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                }
            }

            Section("Quyền riêng tư") {
                Text("API key chỉ được lưu trong macOS Keychain. LinguaFacet không lưu lịch sử dịch và không tự mở trang ủng hộ.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var generalTab: some View {
        Form {
            Section("Dịch vụ") {
                Picker("Công cụ dịch", selection: $settings.provider) {
                    ForEach(TranslationProvider.allCases) { Text($0.title).tag($0) }
                }
            }

            Section("Hành vi") {
                Toggle("Tự sao chép sau khi dịch", isOn: $settings.autoCopy)
                Toggle("Luôn đặt cửa sổ dịch ở trên", isOn: $settings.alwaysOnTop)
                Toggle("Đóng popup sau khi sao chép", isOn: $settings.closeQuickAfterCopy)
                Toggle("Đóng cửa sổ là thoát hẳn ứng dụng", isOn: $settings.quitWhenMainWindowCloses)
                Toggle("Mở cùng macOS", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.setLaunchAtLogin($0) }
                ))
            }

            Section("Dịch vùng chọn") {
                Toggle("Bật dịch vùng chọn và thay thế", isOn: $settings.selectionTranslationEnabled)

                if settings.selectionTranslationEnabled {
                    HStack {
                        Label(
                            accessibility.accessibilityGranted ? "Đã có quyền Accessibility" : "Chưa có quyền Accessibility",
                            systemImage: accessibility.accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(accessibility.accessibilityGranted ? .green : .orange)

                        Spacer()

                        Button("Kiểm tra lại") { accessibility.refreshAccessibilityStatus() }
                        Button("Mở Cài đặt hệ thống") { accessibility.openAccessibilitySettings() }
                        if !accessibility.accessibilityGranted {
                            Button("Yêu cầu quyền") { accessibility.requestAccessibilityFromUser() }
                                .buttonStyle(.glassProminent)
                        }
                    }

                    Text("App không tự hiện hộp thoại quyền. Chỉ nút “Yêu cầu quyền” mới gọi macOS; bạn có thể từ chối mà không bị hỏi lại.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Hai phím tắt dịch vùng chọn và dịch–thay thế đã tắt. Dịch bằng nhập/dán vẫn hoạt động bình thường.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Giao diện") {
                Picker("Ngôn ngữ giao diện", selection: $settings.interfaceLanguage) {
                    ForEach(InterfaceLanguage.allCases) { language in
                        Text(language.nativeName).tag(language)
                    }
                }
                Picker("Chủ đề", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            if !settings.settingsMessage.isEmpty {
                Text(settings.settingsMessage).font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var serviceTab: some View {
        Form {
            Section("Groq · Dịch vụ chính") {
                HStack {
                    Label(
                        settings.hasGroqKey ? "Đã lưu key" : "Chưa có key",
                        systemImage: settings.hasGroqKey ? "checkmark.circle.fill" : "key.slash"
                    )
                    .foregroundStyle(settings.hasGroqKey ? .green : .orange)
                    Spacer()
                    Button("Hướng dẫn lấy API key") {
                        settings.openGroqKeyGuide()
                    }
                    .buttonStyle(.glass)
                }

                SecureField(
                    settings.hasGroqKey ? "Nhập key mới để thay đổi" : "Nhập Groq API key",
                    text: $settings.groqKeyDraft
                )
                .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Lưu key") { settings.saveGroqKey() }
                        .buttonStyle(.glassProminent)
                        .disabled(settings.groqKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Xóa key", role: .destructive) { settings.deleteGroqKey() }
                        .disabled(!settings.hasGroqKey)
                    Spacer()
                    Text("Key chỉ được lưu trong macOS Keychain.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Picker("Model Dịch nhanh", selection: $settings.groqTranslationModel) {
                    ForEach(GroqModel.allCases) { model in
                        Text(model.title).tag(model)
                    }
                }

                Picker("Model Văn phong AI", selection: $settings.groqStyleModel) {
                    ForEach(GroqModel.allCases) { model in
                        Text(model.title).tag(model)
                    }
                }

                Text("GPT-OSS 120B được khuyên dùng. Qwen phù hợp để thử Nhật, Trung, Việt và Anh nhưng hiện vẫn là Preview.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Google Gemini") {
                HStack {
                    Label(
                        settings.hasGeminiKey ? "Đã lưu key" : "Chưa có key",
                        systemImage: settings.hasGeminiKey ? "checkmark.circle.fill" : "key.slash"
                    )
                    .foregroundStyle(settings.hasGeminiKey ? .green : .orange)
                    Spacer()
                    Text("Tùy chọn phụ")
                        .font(.caption).foregroundStyle(.secondary)
                }
                SecureField(
                    settings.hasGeminiKey ? "Nhập key mới để thay đổi" : "Nhập Gemini API key",
                    text: $settings.geminiKeyDraft
                )
                HStack {
                    Button("Lưu key") { settings.saveGeminiKey() }
                        .buttonStyle(.glassProminent)
                        .disabled(settings.geminiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Xóa key", role: .destructive) { settings.deleteGeminiKey() }
                        .disabled(!settings.hasGeminiKey)
                }
                TextField("Model", text: $settings.geminiModel)
            }

            Section("Apple Local · Dự phòng offline") {
                Label("Tự dùng khi Groq thiếu key, mất mạng hoặc trả lỗi", systemImage: "apple.intelligence")
                Text("Nội dung được xử lý trên thiết bị. macOS có thể tải model ngôn ngữ ở lần dùng đầu tiên; máy không hỗ trợ Apple Intelligence vẫn dùng Groq bình thường.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if !settings.settingsMessage.isEmpty {
                Text(settings.settingsMessage)
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var languagesTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 0) {
                languageSelectionRow(
                    title: "Dịch nhanh",
                    symbol: "bolt.fill",
                    detail: "Dùng cho tab Dịch nhanh, dịch vùng chọn và dịch–thay thế.",
                    source: $settings.quickSourceLanguage,
                    target: $settings.quickTargetLanguage
                )
                Divider()
                    .padding(.horizontal, 8)
                languageSelectionRow(
                    title: "Văn phong AI",
                    symbol: "textformat.alt",
                    detail: "Chỉ dùng khi dịch theo preset văn phong.",
                    source: $settings.styleSourceLanguage,
                    target: $settings.styleTargetLanguage
                )
            }
            .padding(6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))

            VStack(alignment: .leading, spacing: 4) {
                Text("Cặp ngôn ngữ thường dùng").font(.title3.weight(.semibold))
                Text("Danh sách dùng chung; mỗi cụm ghi nhớ cặp đang chọn riêng.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(spacing: 9) {
                    ForEach($settings.favoritePairs) { $pair in
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                            Picker("Nguồn", selection: $pair.source) {
                                ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)

                            Image(systemName: "arrow.right").foregroundStyle(.secondary)

                            Picker("Đích", selection: $pair.target) {
                                ForEach(AppLanguage.allCases.filter { $0 != .automatic }) { Text($0.title).tag($0) }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)

                            Button(role: .destructive) {
                                settings.removeFavoritePair(id: pair.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 28, height: 28)
                            .accessibilityLabel("Xóa cặp \(pair.title)")
                        }
                        .padding(11)
                        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            HStack {
                Button(action: settings.addFavoritePair) {
                    Label("Thêm cặp ngôn ngữ", systemImage: "plus")
                }
                .buttonStyle(.glass)
                Spacer()
                Text("\(settings.favoritePairs.count)/10 cặp")
                    .font(.caption).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Thuật ngữ giữ nguyên")
                    .font(.headline)
                Text("Dùng trong Văn phong AI. Dịch nhanh luôn giữ luồng nhập → dịch → sao chép tối giản.")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $settings.protectedTermsText)
                    .font(.system(.body, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(height: 76)
                    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
                    .accessibilityLabel("Danh sách thuật ngữ cần giữ nguyên")
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(8)
    }

    private func languageSelectionRow(
        title: String,
        symbol: String,
        detail: String,
        source: Binding<AppLanguage>,
        target: Binding<AppLanguage>
    ) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 190, alignment: .leading)

            Spacer(minLength: 4)

            Picker("Nguồn \(title)", selection: source) {
                ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            .frame(width: 177)
            .accessibilityLabel("Nguồn \(title)")

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)

            Picker("Đích \(title)", selection: target) {
                ForEach(AppLanguage.allCases.filter { $0 != .automatic }) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            .frame(width: 177)
            .accessibilityLabel("Đích \(title)")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }

    private var stylesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preset văn phong").font(.title3.weight(.semibold))
                    Text("Đánh dấu sao để đưa preset ra thanh chọn nhanh và menu bar.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    if let id = settings.addStylePreset() { selectedStylePresetID = id }
                } label: {
                    Label("Thêm preset", systemImage: "plus")
                }
                .buttonStyle(.glassProminent)
            }

            HSplitView {
                List(selection: $selectedStylePresetID) {
                    ForEach(settings.stylePresets) { preset in
                        HStack(spacing: 9) {
                            Image(systemName: preset.symbol)
                                .foregroundStyle(preset.isFavorite ? .purple : .secondary)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name.isEmpty ? "Preset chưa đặt tên" : preset.name)
                                    .lineLimit(1)
                                Text(preset.isBuiltIn ? "Mặc định" : "Cá nhân")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                settings.setStylePresetFavorite(id: preset.id, favorite: !preset.isFavorite)
                            } label: {
                                Image(systemName: preset.isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(preset.isFavorite ? .yellow : .secondary)
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 28, height: 28)
                            .help(preset.isFavorite ? "Ẩn khỏi thanh chọn nhanh" : "Đưa ra thanh chọn nhanh")
                            .accessibilityLabel(preset.isFavorite ? "Ẩn \(preset.name) khỏi thanh chọn nhanh" : "Đưa \(preset.name) ra thanh chọn nhanh")
                        }
                        .tag(preset.id)
                    }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 220, idealWidth: 235, maxWidth: 260)

                stylePresetEditor
                    .frame(minWidth: 430)
            }
            .background(.quaternary.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))

            HStack {
                Label("Quy tắc giữ nguyên dữ kiện và ý nghĩa luôn được áp dụng phía trên mọi prompt.", systemImage: "checkmark.shield.fill")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(settings.stylePresets.count)/20 preset")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if !settings.settingsMessage.isEmpty {
                Text(settings.settingsMessage)
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .onAppear {
            if selectedStylePresetID == nil || !settings.stylePresets.contains(where: { $0.id == selectedStylePresetID }) {
                selectedStylePresetID = settings.stylePresets.first?.id
            }
        }
        .onChange(of: selectedStylePresetID) { showingAdvancedPrompt = false }
    }

    @ViewBuilder
    private var stylePresetEditor: some View {
        if let id = selectedStylePresetID,
           let index = settings.stylePresets.firstIndex(where: { $0.id == id }) {
            let preset = settings.stylePresets[index]
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Chỉnh preset").font(.headline)
                    if preset.isBuiltIn {
                        Text("MẶC ĐỊNH")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(.purple.opacity(0.13), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                    Spacer()
                    Toggle("Yêu thích", isOn: Binding(
                        get: { settings.stylePresets[index].isFavorite },
                        set: { settings.setStylePresetFavorite(id: id, favorite: $0) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                HStack(spacing: 10) {
                    TextField("Tên preset", text: $settings.stylePresets[index].name)
                        .textFieldStyle(.roundedBorder)
                    Picker("Biểu tượng", selection: $settings.stylePresets[index].symbol) {
                        ForEach(StylePreset.availableSymbols, id: \.self) { symbol in
                            Label(symbol, systemImage: symbol).tag(symbol)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 58)
                }

                if let guidance = preset.guidance {
                    Label(guidance, systemImage: "scope")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                }

                if preset.isBuiltIn {
                    DisclosureGroup(isExpanded: $showingAdvancedPrompt) {
                        promptEditor(index: index)
                            .padding(.top, 8)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nâng cao · Prompt hướng dẫn")
                                .font(.subheadline.weight(.semibold))
                            Text("Chỉ chỉnh khi bạn muốn thay đổi quy tắc chi tiết của preset mặc định.")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    promptEditor(index: index)
                }

                if let message = settings.stylePresetValidationMessage(for: id) {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange)
                } else {
                    Label("Preset hợp lệ và được lưu tự động.", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                }

                Spacer(minLength: 0)

                HStack {
                    Button {
                        showingPromptLibrary = true
                    } label: {
                        Label("Thư viện prompt mẫu", systemImage: "books.vertical.fill")
                    }
                    .buttonStyle(.glass)

                    Spacer()

                    if preset.isBuiltIn {
                        Button("Khôi phục mặc định") { settings.resetStylePreset(id: id) }
                            .buttonStyle(.glass)
                    } else {
                        Button(role: .destructive) {
                            settings.removeStylePreset(id: id)
                            selectedStylePresetID = settings.stylePresets.first?.id
                        } label: {
                            Label("Xóa preset", systemImage: "trash")
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
            .padding(16)
        } else {
            ContentUnavailableView(
                "Chọn một preset",
                systemImage: "textformat.alt",
                description: Text("Chọn preset bên trái hoặc tạo preset mới.")
            )
        }
    }

    private func promptEditor(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Mô tả văn phong").font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(settings.stylePresets[index].prompt.count) ký tự")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            TextEditor(text: $settings.stylePresets[index].prompt)
                .font(.system(size: 13, design: .rounded))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
                .frame(minHeight: 150)
                .accessibilityLabel("Prompt hướng dẫn văn phong")
        }
    }

    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Phím tắt toàn hệ thống").font(.title3.weight(.semibold))
                Text("Bấm vào ô phím tắt rồi nhấn tổ hợp mới. Cần có ⌘, ⌥ hoặc ⌃.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            shortcutRecorderRow("Mở cửa sổ dịch", "macwindow", $settings.openShortcut)
            shortcutRecorderRow("Dịch nhanh vùng chọn", "text.magnifyingglass", $settings.quickShortcut)
            shortcutRecorderRow("Dịch và thay thế", "arrow.uturn.right", $settings.replaceShortcut)

            HStack {
                Label("Dịch trong cửa sổ", systemImage: "arrow.right.circle")
                Spacer()
                Text("⌘Return").font(.system(.body, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
            }
            .padding(.horizontal, 12)

            HStack(spacing: 18) {
                Label("Sao chép", systemImage: "doc.on.doc")
                Text("⌘C").font(.system(.body, design: .rounded).weight(.semibold))
                Divider().frame(height: 18)
                Label("Dán", systemImage: "doc.on.clipboard")
                Text("⌘V").font(.system(.body, design: .rounded).weight(.semibold))
                Divider().frame(height: 18)
                Label("Đóng cửa sổ/menu", systemImage: "xmark.circle")
                Text("Esc").font(.system(.body, design: .rounded).weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .foregroundStyle(.secondary)

            Text("Dịch nhanh chỉ hiện popup để xem hoặc sao chép. Chỉ lệnh “Dịch và thay thế” mới dán vào ứng dụng đang dùng.")
                .font(.caption).foregroundStyle(.secondary)

            Spacer()
            HStack {
                Button("Khôi phục mặc định", action: settings.resetShortcuts)
                    .buttonStyle(.glass)
                Spacer()
                if !settings.settingsMessage.isEmpty {
                    Text(settings.settingsMessage).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
    }

    private func shortcutRecorderRow(
        _ title: String,
        _ icon: String,
        _ shortcut: Binding<GlobalShortcut>
    ) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            ShortcutRecorder(label: title, shortcut: shortcut)
                .frame(width: 142, height: 32)
        }
        .padding(12)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct StylePromptLibraryView: View {
    let onUse: (StylePromptTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Thư viện prompt mẫu").font(.title2.weight(.semibold))
                    Text("Chọn một mẫu làm điểm bắt đầu rồi chỉnh lại theo nhu cầu của bạn.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Đóng") { dismiss() }.keyboardShortcut(.cancelAction)
            }

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(StylePromptTemplate.library) { template in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Label(template.name, systemImage: template.symbol)
                                    .font(.headline)
                                Spacer()
                                Button("Dùng mẫu") { onUse(template) }
                                    .buttonStyle(.glassProminent)
                                    .controlSize(.small)
                            }
                            Text(template.summary)
                                .font(.caption).foregroundStyle(.secondary)
                            Text(template.prompt)
                                .font(.system(size: 12, design: .rounded))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 9))
                        }
                        .padding(13)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 650, height: 520)
    }
}

# System map

Use this map to find the smallest correct change. `→` means the runtime call direction.

| User task or observed problem | Primary files | Runtime flow / first check |
| --- | --- | --- |
| Quick translation result wrong | `AppModel.swift`, `TranslationServices.swift`, `GroqService.swift`, `TranslationCore.swift` | `MainView` → `AppModel.translate()` → provider → `finish()` |
| Style result wrong, too casual/formal, or adds an opener | `StyleTranslationModel.swift`, `TranslationCore.swift`, `Models.swift`, `GroqService.swift` | `StyleTranslationView` → `translateWithStyle()` → structured base/candidate → language validation → `StyledTranslationOutputGuard` |
| Change built-in style prompt | `Models.swift` | Edit `StylePreset.defaults`; preserve user edits with `upgradeLegacyBuiltInPrompts` |
| Add or edit a user style preset | `SettingsView.swift`, `SettingsStore.swift`, `Models.swift` | Settings binding → `stylePresets` UserDefaults serialization → Style tab |
| Groq 413 / TPM / too many requests | `TranslationCore.swift`, `GroqService.swift` | Check `GroqFreeTierPolicy`, then `GroqRequestPacer`, then dynamic completion budget |
| Groq key not found / key prompt | `SettingsStore.swift`, `KeychainStore.swift`, `SettingsView.swift` | Key is stored by account `groq`; never inspect or log its contents |
| First translation without Groq key | `Models.swift`, `SettingsStore.swift`, `AppModel.swift`, `StyleTranslationModel.swift`, `main.swift` | pure onboarding policy → one-time persisted flag → AppKit sheet → Settings Dịch vụ |
| Main support button, quit confirmation, About text, or Ko-fi link | `Models.swift`, `SettingsStore.swift`, `AppRootView.swift`, `SettingsView.swift`, `main.swift` | explicit toolbar/About click or quit-sheet choice → fixed privacy-safe destination → `NSWorkspace.open`; failure returns to Giới thiệu |
| Keychain prompt appears at launch/settings open | `SettingsStore.swift`, `KeychainStore.swift`, `Scripts/build-app.sh` | Check for eager reads first, then verify the installed binary's stable signing identity and designated requirement |
| Provider selection or fallback | `SettingsStore.swift`, `AppModel.swift`, `StyleTranslationModel.swift` | Groq primary → Apple Local fallback upon missing key/network/service error |
| Wrong target language returned | `GroqService.swift`, `Models.swift` | Output JSON → `TranslationLanguageGuard.accepts` → 422/fallback |
| Model list or Groq options | `Models.swift`, `SettingsView.swift`, `SettingsStore.swift` | `GroqModel` enum → saved model choice → Groq request |
| Automatic translation appears too frequently | `AppModel.swift`, `TranslationCore.swift` | 480 ms editor debounce → Groq app-wide 2.1 s request spacing |
| Global shortcut / selected-text issue | `HotKeyManager.swift`, `SelectionController.swift`, `SettingsStore.swift`, `main.swift` | Settings shortcut → HotKey registration → selection controller → `AppModel.beginQuick` |
| Clipboard content changes after selected-text translation | `SelectionController.swift` | Snapshot pasteboard → synthetic Copy/Paste → restore original pasteboard after the operation |
| Window/titlebar/menu/tab behavior | `main.swift`, `AppRootView.swift`, `MainView.swift`, `StyleTranslationView.swift` | full-size transparent titlebar → integrated SwiftUI header with traffic-light clearance → selected module → view |
| Dịch nhanh and Văn phong AI use the wrong shared language pair | `SettingsStore.swift`, `Models.swift`, `main.swift`, both module views | module-scoped persisted selection → module menu branch → only that module's request |
| Main window can be dragged too short | `DesignTokens.swift`, `main.swift` | attach hosting view → set frame/content minimum → delegate clamps every resize to 820×560 |
| Empty band below editors or status gets clipped | `MainView.swift`, `StyleTranslationView.swift` | measured desired height → screen-clamped window growth → editors fill remaining viewport → gesture scrolling at ceiling |
| Window jumps while typing / Reduce Motion | `main.swift`, `AppRootView.swift` | content-height callback → clamped window resize → animate only when system Reduce Motion is off |
| Narrow-window layout clips or becomes crowded | `MainView.swift`, `StyleTranslationView.swift`, `Docs/DESIGN-SYSTEM.md` | geometry breakpoint → side-by-side editors or stacked editors; primary content remains first |
| VoiceOver label/focus/selected-state issue | `FocusedTextEditor.swift`, `ShortcutRecorder.swift`, `AppRootView.swift`, editor cards | native control accessibility label/role/value → logical focus order → selected/busy/error trait |
| `⌘Return`, Escape, Copy or Paste fails | `MainView.swift`, `StyleTranslationView.swift`, `main.swift` | focused editor/menu command → local primary action or dismiss action; never replace standard Edit commands |
| Add optional context or protected terms to Văn phong AI | `SettingsStore.swift`, `TranslationCore.swift`, `StyleTranslationModel.swift`, `StyleTranslationView.swift` | non-secret style guidance → `TranslationRequestContext` → same single Groq style request → deterministic prompt tests |
| Context/glossary control UI | `TranslationContextControl.swift`, `StyleTranslationView.swift`, `SettingsView.swift` | session context + persistent terms → style request only; never route into Dịch nhanh |
| Repeated Groq 413 after several short calls | `TranslationCore.swift`, `GroqService.swift` | prompt/completion token reservation → rolling 60 s TPM window → RPM spacing → request |
| Inconsistent spacing/control size | `DesignTokens.swift`, `Docs/DESIGN-SYSTEM.md`, affected views | shared `TQLayout` token → native control/material |
| Release signing / Keychain trust | `Scripts/build-app.sh`, `Docs/SIGNING.md`, `KeychainStore.swift` | `TRANSLATE_QUICK_SIGN_IDENTITY` → codesign DR → Keychain ACL continuity |
| Build or app metadata | `Scripts/build-app.sh`, `Resources/Info.plist`, `Docs/SIGNING.md` | test-core → swiftc → assemble bundle → stable local sign for installed releases (ad-hoc only for isolated development candidates) |
| Interface language, untranslated label, or wrong fresh-install default | `Localization.swift`, `SettingsStore.swift`, `Resources/*.lproj`, `SettingsView.swift`, `main.swift` | persisted `interfaceLanguage` (English fallback) → SwiftUI locale/AppKit lookup → localized resources; never route UI names into prompts |
| DMG contains stale resources or wrong app | `Scripts/build-app.sh`, `Scripts/build-dmg.sh`, `Resources/Info.plist` | clean bundle assembly → signed app → DMG staging → read-only mount and verification |

## Translation runtime contracts

### Quick translation

`AppModel` creates a `RemoteTranslationConfiguration` only after the input is non-empty. `TranslationServices` routes Groq to `GroqService.translate`. `TranslationPromptFactory.quickTranslation` owns the exact prompt contract. Quick requests contain only source text plus source/target language—no hidden context or glossary. Groq returns `{"translation":"..."}`. `GroqService` validates target language before `AppModel` publishes the result.

### Style translation

`StyleTranslationModel` selects a `StylePreset` and calls one Groq request. `TranslationPromptFactory.styledTranslation` instructs the model to construct a faithful base, apply observable style features, then self-check factual, pragmatic, and discourse-unit fidelity. It permits surface register/courtesy changes while preserving speech-act force, hierarchy, urgency, certainty, commitments, emotion, and the source's opening/closing social moves. Groq returns `{"base_translation":"...","translation":"..."}`. After target-language validation, `StyledTranslationOutputGuard` removes a recognized leading social opener only when it has no anchor in either source or base; genuine source greetings pass unchanged. The view can reveal the base translation for comparison.

### Failure handling

Groq key, network, HTTP, JSON, or target-language failures are converted to `TranslationServiceError`. Quick and style models then start Apple Local when available. Apple Local is never used when Groq succeeds.

The UI must show a recovery action for terminal failures: Cancel while busy, Retry after failure, and a clear explanation when both Groq and Apple Local are unavailable. Provider detail is secondary to the user-facing outcome.

Before the first keyless Groq request, the app pauses the action and presents onboarding once. Choosing setup opens the Dịch vụ tab; choosing later preserves normal Apple Local fallback behavior on subsequent attempts.

## UX runtime contracts

- Editor controls use a minimum 20×20 pt hit target; routine toolbar actions use 28×28 pt.
- Source and result editors expose stable Vietnamese accessibility labels.
- Quick translation remains automatic after debounce; `⌘Return` bypasses the wait and translates immediately.
- Selected-text commands restore the previous clipboard contents after synthetic Copy/Paste.
- Side-by-side is preferred when space allows; narrow windows stack source above result without losing actions.
- The main window has a hard 820×560 frame minimum in both modules. Content may request height up to the current screen's visible work area minus 12 pt.
- Editors always fill the viewport left after controls/status. Desired text height drives window growth; once screen-clamped, the native text view scrolls without a visible scrollbar.
- Quick and Style persist source/target languages independently. Favorite language pairs are shared inventory, not shared active selection.
- Motion is functional and interruptible. Reduce Motion disables animated window resizing and nonessential transitions.
- Support is secondary, labeled, and voluntary. It appears once in the main toolbar, in Settings → Giới thiệu, and as an explicit choice in the quit confirmation; it never opens automatically, changes entitlement, or records payment state. Do not duplicate it in the status menu.
- Quit requests share one AppKit confirmation. `Ở lại` and Escape cancel termination, `Thoát` replies to macOS once, and `Ủng hộ trên Ko-fi` cancels termination before opening the fixed URL.

### Context and protected terms

`TranslationRequestContext` normalizes one Style-session note plus up to 50 unique protected terms. The prompt labels both as untrusted reference data. Only the Groq style request receives them. Dịch nhanh deliberately has no context/glossary path. Apple Translation has no prompt channel, so the Style fallback UI discloses that custom guidance is not applied instead of pretending to honor it.

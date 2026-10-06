# Architecture

## Layers and allowed dependencies

```text
SwiftUI / AppKit views
        ↓ actions + bindings only
State models (AppModel, StyleTranslationModel, SettingsStore)
        ↓ task requests, state transitions
Translation services (TranslationServices, GroqService, Apple Translation)
        ↓ prompt policy, quota policy, HTTP / framework calls
Translation core (TranslationCore, Models)
        ↓ pure prompt contracts, validation, values, rate guardrails
Platform boundary (KeychainStore, HotKeyManager, SelectionController, SpeechService)
```

- Views may depend on state models and display-only values.
- State models may depend on services and platform boundaries.
- Services may depend on `TranslationCore` and `Models`; they must not depend on views.
- `TranslationCore` is deliberately deterministic and has no Keychain, URLSession, SwiftUI, or Apple Intelligence dependency.
- Clipboard capture/restore and accessibility automation stay behind platform boundaries; views receive only values and actions.

## Key components

| Component | Responsibility | Do not put here |
| --- | --- | --- |
| `TranslationCore.swift` | Groq prompt contracts, free-tier policy, request pacing, structured result types, pure style-output safety guards | UI state, secrets, HTTP code |
| `GroqService.swift` | URLSession request, headers, Groq JSON parsing, provider-specific errors | preset storage or view state |
| `TranslationServices.swift` | Provider routing for quick translation | Groq prompt strings |
| `AppModel.swift` | Quick translation lifecycle, debounce, fallback, copy/replace actions | HTTP request assembly |
| `StyleTranslationModel.swift` | Style translation lifecycle, fallback, base-result state | prompt text or quota calculations |
| `SettingsStore.swift` | Persistent non-secret settings and Keychain orchestration | network calls |
| `Localization.swift` + `Resources/*.lproj` | interface-language inventory, current-locale lookup, localized UI resources | translation prompt language names or API behavior |
| `SupportDestination` / `SettingsStore.openSupportPage` | fixed Ko-fi URL and explicit browser-open boundary | analytics, payment state, translated content, automatic browser opens |
| `Models.swift` | App enums, languages, style preset values, language guard | API implementation |
| `TranslationContextControl.swift` | Style-only progressive-disclosure UI for session context and protected terms | Quick translation UI, prompt construction, or persistence rules |
| `DesignTokens.swift` | Small shared spacing, radius, control-size, and breakpoint values | feature state or one-off page behavior |
| `FocusedTextEditor.swift` | AppKit text editing bridge, focus, caret, and editor accessibility semantics | translation state or provider logic |
| `SelectionController.swift` | Accessibility selection bridge and pasteboard preservation | translation requests or UI presentation |
| `Docs/DESIGN-SYSTEM.md` | Stable visual/interaction tokens and platform rules | provider or prompt policy |

## Hotspots

1. **`TranslationCore.swift`**: changing prompts or token math affects every Groq request. Add a smoke test first.
2. **`Models.swift` built-in presets**: saved presets persist. Use legacy-upgrade logic only for values that exactly match old defaults so user edits survive.
3. **`SettingsStore.swift` / `KeychainStore.swift`**: a careless read can trigger macOS Keychain UI. Treat this as a privacy-sensitive boundary.
4. **Fallback paths**: every Groq change must keep Apple Local usable for unavailable network/key/provider states.
5. **Window sizing and chrome**: attach the hosting view before applying frame/content limits. The main window uses a full-size transparent titlebar with hidden redundant title text; SwiftUI reserves traffic-light clearance. Manual dragging passes through a hard 820×560 floor; content growth is capped from the active screen's visible frame, not a fixed device-specific height. Honor Reduce Motion for animation and hover transitions.
6. **Custom AppKit controls**: `FocusedTextEditor` and `ShortcutRecorder` must explicitly expose labels, roles, values, focus, and actions to accessibility APIs.
7. **Groq admission control**: free-tier protection must account for both RPM and the rolling sum of prompt + reserved completion tokens. A fixed delay alone does not prevent TPM 413 errors.
8. **Styled output guard**: keep it narrow and source/base-anchored. It may reject a recognized unrequested leading social opener; it must not become a general translation rewriter or replace prompt quality.
9. **Groq onboarding**: eligibility is a pure policy value; persistence belongs to `SettingsStore`; presentation and Settings navigation belong to `AppDelegate`. Models only request presentation and stop the current action when it is shown.
10. **Voluntary support and quit**: the destination is a constant value with no query/fragment. `AppDelegate` owns the single termination sheet and replies to macOS exactly once; `SettingsStore` owns browser open/failure handling. Support cancels termination before opening and remains separate from translation, Keychain, and user data.
11. **Interface localization**: `InterfaceLanguage` is a UI preference only. API prompts use `AppLanguage.promptName`, a stable English value, so changing the UI language cannot alter model instructions or token behavior. New installs default to English.

## Extension recipe

For a new translation-oriented capability:

1. Define request/output values and deterministic prompt/policy in `TranslationCore.swift`.
2. Add a single provider method in `GroqService.swift` with declared JSON fields.
3. Add a state model, or extend the appropriate existing model, to own cancellation, errors, fallback, and view state.
4. Add UI that only binds to the model.
5. Add smoke tests for the prompt/output/quota rules.
6. Update `SYSTEM-MAP.md`, `CHECKPOINT.md`, and this architecture document if dependencies or runtime flow changed.

## Growth controls

- Keep Dịch nhanh context-free and glossary-free. Style-only guidance may extend the existing single style request through a small value type rather than a new feature service.
- A user action has one owner model, one cancellable task, and one terminal state. Do not coordinate async work in a view.
- Persist only durable user choices. Ephemeral input, detected language, loading state, and error state belong to the session model.
- Persist active languages per module (`quick*` and `style*`). Keep favorite pairs shared and route application through `AppModule`; never reintroduce one global active pair.
- Reusable visual constants live in a small design-token namespace; reusable behavior lives in a focused component. Do not create a generic abstraction before two real consumers exist.
- Every additional Groq field must have a prompt-contract test and remain compatible with Apple Local fallback or degrade clearly.
- Style-session context belongs to `StyleTranslationModel`; its protected-term list is a durable non-secret setting. Neither may silently affect `AppModel` or become translation history.
- A new top-level tab requires an explicit product-scope decision and a system-map update. Translation context, glossary, diagnostics, and help should use progressive disclosure before adding navigation.

## Deliberate constraints

- No raw API keys outside Keychain.
- Groq onboarding may persist only a non-secret “already presented” Boolean; it must never read or copy the key itself.
- No automatic remote translation based on clipboard changes.
- No model reasoning in user-visible output.
- No multi-step Groq style pipeline by default; use one structured request with faithful base + final style result.
- No broad heuristic rewriting after a model response. Deterministic guards must target an objectively testable violation, preserve the rest of the candidate, and have multilingual regression cases.
- No unrequested AI feature expansion beyond translation quality and writing style.
- No startup/translation support prompt, automatic browser open, payment verification, donor flag, or feature gating. The only exit interception is the single user-initiated quit confirmation.
- No secrets, build caches, or Keychain exports in project backups.
- No visual effect that reduces text contrast, hides focus, or makes the interface depend on animation.

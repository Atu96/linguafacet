# Changelog

## 1.12.1 — 2026-10-06

- Licensed the source under PolyForm Noncommercial 1.0.0 with Atu as the copyright holder.
- Added the license and required copyright notice to the app bundle and public project documentation.
- Clarified that LinguaFacet is source-available for noncommercial purposes, not OSI open source.

## 1.12.0 — 2026-10-06

- Renamed the product to **LinguaFacet — AI Translator** while preserving the existing bundle identifier for Keychain and Accessibility continuity.
- Added an interface-language preference with English as the fresh-install default plus Vietnamese, Simplified Chinese, Japanese, Korean, French, German, and Spanish.
- Kept interface localization independent from translation source/target languages and API prompt language names.
- Added clean-bundle assembly and a drag-to-Applications DMG build; stale localization resources can no longer leak from earlier builds.
- Built, mounted, signature-checked, installed, and launched 1.12.0/build 43 from `/Applications/LinguaFacet.app`.

## 1.11.5 — 2026-10-06

- Unified the native titlebar and app header, removing the redundant standalone title strip while preserving traffic-light controls and window dragging.
- Restyled Support and Settings as muted borderless actions with a subtle hover-only highlight and Reduce Motion support.
- Built and installed build 42 with matching staged/installed hashes.

## 1.11.4 — 2026-10-06

- Reduced the main-window Support action to a compact secondary pill while preserving its visible label and accessibility metadata.
- Built and installed build 41 with matching staged/installed hashes.

## 1.11.3 — 2026-10-06

- Restored the compact labeled Support action in the main window while keeping it out of the status menu.
- Added explicit help and VoiceOver text, with browser-failure recovery through Settings → About.
- Built and installed build 40 with matching staged/installed hashes.

## 1.11.2 — 2026-10-06

- Removed the decorative heart from the native Ko-fi button because AppKit could overlap it with the Vietnamese title.
- Kept a clean text-only button and installed build 39 with matching staged/installed hashes.

## 1.11.1 — 2026-10-06

### Focused quit flow

- Removed Support from the translation toolbar and status menu.
- Added a native Vietnamese quit confirmation without a generic greeting.
- Made `Ở lại` and Escape the safe paths; Support cancels quitting before opening Ko-fi.
- Added an in-progress translation warning and duplicate-sheet protection.
- Built and installed 1.11.1/build 38 with matching staged/installed executable hashes.

## 1.11.0 — 2026-10-06

### Voluntary support

- Added a small labeled Support shortcut in the main window and status menu.
- Added a full Settings → About section with voluntary Ko-fi copy and privacy disclosure.
- Kept support separate from startup, translation results, failures, feature access, and quitting.
- Added a fixed, tested Ko-fi destination and a manual recovery message if the browser cannot open.
- Added GitHub funding metadata and a concise English README.

### Maintenance

- Preserved a verified 1.10.3/build 36 recovery checkpoint before implementation.
- Built and installed 1.11.0/build 37 with matching staged/installed executable hashes.

## 1.9.1 — 2026-08-24

### Faster Quick flow

- Removed the context/glossary control and all hidden guidance from Dịch nhanh.
- Kept advanced context and protected terms only in Văn phong AI.

### Stronger style prompts

- Separated immutable meaning/pragmatic force from the surface features a style may change.
- Deepened all four built-in presets and all six prompt-library templates with conditional domain/audience inference, observable target-language behavior, and explicit non-invention limits.
- Removed greeting-token priming from the active Bạn bè prompt and stopped anchoring Công việc to English example phrases.
- Added safe migration for known built-in defaults while preserving user-edited prompts.
- Added regression tests and `Docs/PROMPT-AUDIT-1.9.1.md`.

## 1.9.0 — 2026-08-24

### Translation quality

- Added optional task context and persistent protected terms to the existing single Groq/Gemini request.
- Added deterministic context/prompt regression tests.
- Added rolling TPM-aware request admission alongside RPM pacing to prevent successive short calls from accumulating into Groq Free 413 errors.

### Reliability and privacy

- Removed eager Groq/Gemini Keychain reads from app and Settings startup.
- Added explicit Gemini key save/delete behavior matching Groq.
- Preserved clipboard contents around selected-text preview and replacement.
- Added Cancel/Retry states and immediate `⌘Return` translation.

### UI and accessibility

- Added adaptive two-column/stacked translation layout and Reduce Motion-aware window resizing.
- Added detected source-language feedback and consistent Vietnamese action labels.
- Added source/result editor labels, appearance-aware caret, 28 pt icon actions, selected-tab semantics, and a fully accessible shortcut recorder.
- Moved built-in raw prompt editing behind an advanced disclosure while keeping custom presets directly editable.
- Added shared design tokens and a release accessibility checklist.

### Maintenance

- Added backup/restore, UX audit, design system, signing, QA, release-checklist, and changelog documentation.
- Preserved the verified 1.8.1/build 27 recovery backup before runtime changes.
- Installed and launched 1.9.0/build 28 from `/Applications` with the stable `Translate Quick Local Signing` identity trusted only for Code Signing on this Mac.

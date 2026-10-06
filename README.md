# LinguaFacet — AI Translator

A native macOS translation utility with fast two-column translation, selected-text shortcuts, and writing-style presets.

## What it does

- Translates automatically after you pause typing, with `⌘Return` for an immediate request.
- Keeps Quick Translation simple: paste or type, translate, then copy.
- Offers a separate Writing Style workspace with editable presets for natural conversation, academic writing, professional communication, and peers.
- Remembers independent source/target language pairs for Quick Translation and Writing Style.
- Translates selected text in place or shows a compact result panel through configurable global shortcuts.
- Uses Groq as the primary service, with Apple Local as an offline/failure fallback and Gemini as an optional secondary provider.
- Stores API keys only in macOS Keychain.
- Does not include OCR or translation history.

## Requirements

- Apple silicon Mac
- macOS 26.4 or later
- A user-created Groq API key for the primary cloud translation service
- Accessibility permission only for selected-text translation and replacement

The normal input/paste workflow does not need Accessibility permission. Apple Local availability depends on the Mac, language pair, and downloaded system models.

## Shortcuts

- `⌘⇧Space` — open the main translation window
- `⌘⇧T` — translate selected text and show a compact result
- `⌘⇧R` — translate selected text and replace it in place

All three shortcuts can be changed in Settings.

## Build from source

Run:

```bash
./Scripts/build-app.sh
```

The app is created at `dist/LinguaFacet.app`. Run `Scripts/build-dmg.sh` to create the drag-to-Applications DMG. Local builds are signed as documented in [Docs/SIGNING.md](Docs/SIGNING.md); public distribution still requires Developer ID signing and Apple notarization.

## Support

If LinguaFacet saves you time, you can [support its continued development on Ko-fi](https://ko-fi.com/atu1202). It helps with fixes and improvements, but it is completely optional. Every advertised feature remains available without supporting. ❤️

The app offers support from the small labeled action in the main window, Settings → About, and as an optional choice in the quit confirmation. Ko-fi opens only after an explicit choice; staying or pressing Escape keeps the app open. The link contains no translated text, usage history, account details, or other private data.

## Project status

LinguaFacet is focused on translation quality, tone, and context. Subtitle processing, speech-to-text, OCR, and translation history are intentionally outside the current scope.

No source-code license has been declared in this repository. Availability of source does not by itself grant reuse or redistribution rights.

## Maintenance documents

- [Runtime system map](SYSTEM-MAP.md)
- [Architecture](ARCHITECTURE.md)
- [UX audit](Docs/UX-AUDIT-2026-08-24.md)
- [Native macOS design system](Docs/DESIGN-SYSTEM.md)
- [Release checklist](Docs/RELEASE-CHECKLIST.md)
- [Signing and Keychain continuity](Docs/SIGNING.md)
- [Changelog](CHANGELOG.md)

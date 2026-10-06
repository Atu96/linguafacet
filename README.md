# LinguaFacet — AI Translator

A small native macOS translator for quick everyday translation and tone-aware rewriting.

## What it does

- Translates automatically after you pause typing, with `⌘Return` for an immediate request.
- Keeps Quick Translation simple: paste or type, translate, then copy.
- Offers a separate Writing Style workspace with editable presets for natural conversation, academic writing, professional communication, and peers.
- Remembers independent source/target language pairs for Quick Translation and Writing Style.
- Translates selected text in place or shows a compact result panel through configurable global shortcuts.
- Uses Groq as the primary service, with Apple Local as an offline/failure fallback and Gemini as an optional secondary provider.
- Stores API keys only in macOS Keychain.
- Does not include OCR or translation history.

## Interface languages

New installations default to English. The interface can be changed in Settings to English, Vietnamese, Simplified Chinese, Japanese, Korean, French, German, or Spanish. This preference changes only the app’s labels and menus; translation source/target languages and AI prompt behavior remain independent.

## Quick start

1. Add your own Groq API key in Settings → Services.
2. Type or paste text into Quick Translation; the result appears automatically after a short pause.
3. Use AI Tone when you need natural conversation, academic, professional, peer, or custom wording.

Groq is the primary translation service. Apple Local remains available as an offline/failure fallback when the Mac and selected language pair support it.

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

## Distribution status

[Download LinguaFacet 1.12.2 for Apple silicon](https://github.com/Atu96/linguafacet/releases/tag/v1.12.2). The public Release includes the arm64 DMG and a SHA-256 checksum file.

Open the DMG and drag LinguaFacet into Applications.

The current Release is arm64-only and ad-hoc signed. It is not signed with an Apple Developer ID or notarized by Apple, so macOS may warn when opening it on another Mac. Only open a copy from a source you trust, and do not disable Gatekeeper across the system.

## Privacy and limitations

- API keys are stored in macOS Keychain and are never committed to this repository.
- Translation text is sent to the selected cloud provider when Groq or Gemini is used. Apple Local processes supported requests on the device.
- Accessibility permission is used only for selected-text translation and replacement.
- LinguaFacet does not keep translation history and does not include OCR, subtitle processing, or speech-to-text.
- The Ko-fi page opens only after an explicit Support action; translated text and usage data are not added to its URL.

## Support

If LinguaFacet saves you time, you can [support its development on Ko-fi](https://ko-fi.com/atu1202). No pressure — thanks for using it! ❤️

Support is optional and never unlocks features. The app keeps working normally if you do not support it.

## Build from source

Run:

```bash
./Scripts/build-app.sh
```

The app is created at `dist/LinguaFacet.app`. Run `Scripts/build-dmg.sh` to create a local drag-to-Applications DMG. Signing and Keychain-continuity details are documented in [Docs/SIGNING.md](Docs/SIGNING.md).

## Project status

LinguaFacet is focused on translation quality, tone, and context. Subtitle processing, speech-to-text, OCR, and translation history are intentionally outside the current scope.

## License

Copyright © 2026 Atu. All rights reserved.

LinguaFacet is **source-available** under the [PolyForm Noncommercial License 1.0.0](LICENSE). You may inspect, study, modify, and share the software for permitted noncommercial purposes under that license. Commercial use, commercial redistribution, resale, sublicensing, and commercial derivative products require separate written permission from Atu.

This is a noncommercial source-available license, not an OSI-approved open-source license.

## Developer documentation

- [Runtime system map](SYSTEM-MAP.md)
- [Architecture](ARCHITECTURE.md)
- [UX audit](Docs/UX-AUDIT-2026-08-24.md)
- [Native macOS design system](Docs/DESIGN-SYSTEM.md)
- [Release checklist](Docs/RELEASE-CHECKLIST.md)
- [Signing and Keychain continuity](Docs/SIGNING.md)
- [Changelog](CHANGELOG.md)

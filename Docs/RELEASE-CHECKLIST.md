# Release checklist

Record pass/fail and a short note for every installable release.

## Automated

- [ ] `./Scripts/test-core.sh`
- [ ] `./Scripts/build-app.sh`
- [ ] `codesign --verify --deep --strict "dist/Translate Quick.app"`
- [ ] Version/build in source, built app, installed app, and `CHECKPOINT.md` match.
- [ ] Installed executable SHA-256 is recorded; no old process or old binary is being tested.

## Core translation

- [ ] Quick auto-translation after typing pause.
- [ ] `⌘Return` translates immediately.
- [ ] Cancel stops an in-flight Quick request; Retry recovers from a terminal error.
- [ ] Style translation returns final and base comparison in the target language.
- [ ] Switching tabs during/in-between requests does not stall or reveal a stale result.
- [ ] Groq success, missing key, invalid key, rate/quota error, offline state, and Apple Local fallback are understandable.
- [ ] Dịch nhanh exposes and sends no context/glossary; its flow remains input/paste → translate → copy.
- [ ] Optional context and protected terms remain in one Văn phong request and do not alter facts or target language.
- [ ] Built-in style presets remain observably distinct on suitable text while preserving speech-act force, certainty, hierarchy, commitments, urgency, and emotion.
- [ ] A style candidate cannot prepend a recognized social opener when neither source nor faithful base has one; a genuine source greeting remains intact.
- [ ] Peer-style interactional particles and omitted subjects preserve softening, alignment, and shared-versus-unilateral action.
- [ ] Saved legacy defaults migrate to current prompts; a user-edited prompt is never overwritten.

## Existing features

- [ ] Favorite language pairs and favorite style presets appear in the expected menus.
- [ ] Dịch nhanh and Văn phong AI remember independent active language pairs; choosing a favorite in one module does not change the other.
- [ ] Editing, adding, deleting, favoriting, and restoring style presets work.
- [ ] Three configurable global shortcuts register and restore to defaults.
- [ ] Selected-text preview and replace work with Accessibility permission.
- [ ] Previous clipboard contents survive preview and replace.
- [ ] Speak, Dán, Sao chép, Xóa, swap languages, and auto-copy behave as configured.
- [ ] A fresh keyless Groq user sees onboarding on the first Quick, Style, or selected-text translation attempt only.
- [ ] “Thiết lập Groq” opens Settings → Dịch vụ; “Hướng dẫn lấy API key” opens `https://console.groq.com/keys`.
- [ ] Choosing “Để sau” does not repeatedly show the sheet and leaves Apple Local fallback available.
- [ ] Main-toolbar `Ủng hộ`, Settings → Giới thiệu, and the quit confirmation use exactly `https://ko-fi.com/atu1202` with no query/fragment; the status menu has no duplicate support command.
- [ ] `⌘Q`, the app menu, and status-menu Quit show only one confirmation. `Ở lại` and Escape keep the app open; `Thoát` terminates; Support cancels termination before opening Ko-fi.
- [ ] An active translation adds the interruption warning, and repeated quit requests do not stack sheets.
- [ ] Failed browser opening keeps the app running and exposes a selectable manual URL.

## Keyboard and accessibility

- [ ] `⌘C`, `⌘V`, `⌘X`, `⌘A`, Undo/Redo use the focused editor.
- [ ] Escape closes every transient surface and the frontmost app window where documented.
- [ ] Full Keyboard Access reaches tabs, language selectors, editor actions, primary action, settings, and shortcut recorder in logical order.
- [ ] VoiceOver announces source editor, result editor, selected tab, shortcut value, busy state, error, and recovery action.
- [ ] Every clickable target is at least 20×20 pt; routine toolbar actions are 28×28 pt.

## Visual and motion

- [ ] Light appearance: hierarchy, contrast, separators, focus, and caret are clear.
- [ ] Dark appearance: hierarchy, contrast, separators, focus, and caret are clear.
- [ ] Narrow window stacks without clipping; wide window remains balanced.
- [ ] Manual resize cannot make either module smaller than 820×560, including after launch, tab changes, and content-driven resizing.
- [ ] Empty content still expands both editor cards to fill the usable window area; no large blank band appears below them.
- [ ] Long content grows the window to the active screen ceiling, then scrolls by gesture with no visible scrollbar.
- [ ] One- and two-line warning/status messages remain vertically centered with visible bottom padding.
- [ ] Short and long translations resize up to the maximum, then use a thin scroll area.
- [ ] Reduce Motion removes nonessential transitions and animated window resizing.
- [ ] No control or tab touches the title-bar edge; no duplicated settings/model controls reappear in translation surfaces.

## Security and backup

- [ ] No API key appears in terminal, logs, UserDefaults, source, tests, crash text, or backup.
- [ ] Opening app/settings does not read a secret merely to show key status.
- [ ] Backup manifest and restore instructions are current.
- [ ] Signing identity and designated requirement are recorded for the build.
- [ ] Support URL contains no translated text, usage details, file paths, account data, cookie, or tracking parameter.

# Translate Quick design system

## Direction

Native macOS utility: quiet, fast, keyboard-first, and content-first. Liquid Glass separates navigation and controls from translation content; it must not reduce readability or become a decorative layer on every card.

Use SF Pro through system text styles and SF Symbols. Do not bundle a web font. Use native controls and focus effects whenever possible.

## Tokens

| Token | Value | Use |
| --- | ---: | --- |
| Space 1 | 4 pt | icon/text micro-gap |
| Space 2 | 8 pt | related controls |
| Space 3 | 12 pt | compact card padding |
| Space 4 | 16 pt | standard section padding |
| Space 5 | 24 pt | major section separation |
| Radius small | 8 pt | compact controls |
| Radius medium | 12 pt | editors and panels |
| Routine control | 28×28 pt | icon button, tab auxiliary action |
| Absolute minimum target | 20×20 pt | macOS minimum; use only in dense settings rows |
| Tab height | 34–36 pt | top-level Dịch nhanh / Văn phong AI |
| Main-window minimum | 820×560 pt | hard readable floor for both translation modules |
| Main-window maximum height | visible screen − 12 pt | switch editor content to gesture scrolling beyond this point |
| Motion fast | 0.16 s | hover/pressed/fade feedback |
| Motion normal | 0.22 s | meaningful view state transition |

Use semantic system colors: `.primary`, `.secondary`, `.accentColor`, `.red`, system materials, and separators. Never hard-code a caret or body text color. Color is never the only busy, selected, success, or error signal.

## Surface hierarchy

1. Window background: system window material/color.
2. Top navigation and compact floating controls: Liquid Glass/system glass when available.
3. Editor surfaces: quiet material with a visible boundary in light and dark appearances.
4. Popovers/sheets: native material and shadow; one clear dismissal route.

Avoid stacked blur, strong gradients behind text, large decorative glows, mixed icon weights, and simultaneous animation of multiple regions.

## Interaction contracts

- Primary action per module: translate now. Automatic quick translation remains, while `⌘Return` performs it immediately.
- While busy: primary action becomes Cancel and remains keyboard reachable.
- After failure: show a nearby Retry action and a plain-language recovery message.
- Escape dismisses menus, settings, popup, or the frontmost app window as appropriate.
- Selected tabs use label, icon emphasis, and selected semantics; inactive tab icons do not compete visually.
- Quick and Style language choices are separate active state. Favorite pairs are shared shortcuts and must update only the module from which they are selected.
- Icon-only controls have a tooltip and Vietnamese accessibility label.
- Read-only output is visually and semantically distinct from editable source.
- Keep one compact labeled `Ủng hộ` action in the main toolbar between provider status and Settings. Do not duplicate it in the status menu. The full message belongs in Settings → Giới thiệu and the user-initiated quit confirmation.
- The main window uses one integrated full-size title/header surface: hide the redundant title text, reserve 112 pt for native traffic lights, and keep the rest draggable.
- Secondary header actions are borderless and muted at rest. A subtle 9% semantic foreground fill and stronger glyph color appear on hover; Reduce Motion disables the transition animation.
- The quit confirmation uses native controls, the direct title “Bạn muốn thoát Translate Quick?”, and no conversational greeting. `Ở lại` is the default, Escape stays, and Support remains visually secondary.

## Adaptive layout

- Wide: source and result side-by-side with equal visual weight.
- Narrow: source above result; language and primary actions remain visible before secondary tools.
- Content-driven height is clamped between 560 pt and the active screen's usable height minus 12 pt. AppKit frame/content limits and the resize delegate enforce the same floor.
- Editors fill all remaining vertical space at every window height; do not leave unused space beneath fixed-height cards.
- Error/status copy is vertically centered in a protected row of at least 48 pt and may wrap to two lines without touching the window edge.
- Text remains scrollable with mouse/trackpad after the height ceiling, but no persistent scrollbar is shown.
- Keep primary controls away from the title-bar edge and preserve predictable gutters using the 4/8 pt rhythm.

## Copy language

Use short Vietnamese verbs and outcome-first status:

- Dán, Sao chép, Xóa, Nghe, Đổi chiều, Dịch ngay, Hủy, Thử lại.
- Đang dịch… / Đã dịch bằng Groq / Đang dùng Apple Local dự phòng.
- Avoid raw HTTP or model terms in the primary message; offer details only when they help recovery.

## Accessibility release bar

- 4.5:1 normal-text contrast and 3:1 large text/UI graphics where applicable.
- Every meaningful control has a label; text editors have stable role/label/value behavior.
- Logical keyboard and VoiceOver order follows visual order.
- System focus ring remains visible.
- Reduce Motion disables nonessential movement and animated window resizing.
- Verify both appearances independently.

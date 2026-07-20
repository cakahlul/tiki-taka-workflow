# Accessibility Checklist (WCAG 2.1 AA)

Detailed reference for the `frontend-ui-engineering` skill.

## Perceivable

- [ ] **Text alternatives**: All non-text content (images, icons, charts) has `alt` text or an accessible name. Decorative images use `alt=""` or `aria-hidden="true"`.
- [ ] **Color contrast**: 4.5:1 for normal text, 3:1 for large text (≥18.66px bold or ≥24px) and UI components/graphics.
- [ ] **Not color alone**: State is conveyed with icon/text/pattern in addition to color (e.g. error field has an icon + message, not just a red border).
- [ ] **Resize**: Content is usable when zoomed to 200% without loss of function or horizontal scrolling.
- [ ] **Reflow**: Content reflows at 320px width without two-dimensional scrolling.

## Operable

- [ ] **Keyboard**: Every interactive element is reachable and operable by keyboard (Tab, Shift+Tab, Enter, Space, Arrow keys where appropriate).
- [ ] **No keyboard trap**: Focus can always move away from a component (except intentional modals, which trap and release on close).
- [ ] **Focus visible**: A clear focus indicator is shown on all focusable elements (never `outline: none` without a replacement).
- [ ] **Focus order**: Tab order follows a logical reading order.
- [ ] **Skip link**: A "skip to main content" link is present on pages with repeated navigation.
- [ ] **Tap targets**: Interactive targets are at least 24×24px (44×44px recommended on touch).
- [ ] **Motion**: Respect `prefers-reduced-motion`; avoid content that flashes more than 3× per second.

## Understandable

- [ ] **Language**: `<html lang="...">` is set.
- [ ] **Labels**: Every form control has an associated `<label>` (via `htmlFor`/`id`) or `aria-label`/`aria-labelledby`.
- [ ] **Error identification**: Errors are described in text, associated to the field via `aria-describedby`, and `aria-invalid` is set.
- [ ] **Instructions**: Required fields, formats, and constraints are stated before the user submits.
- [ ] **Consistent navigation**: Repeated components appear in the same relative order across pages.

## Robust

- [ ] **Valid HTML**: No duplicate `id`s; elements are properly nested.
- [ ] **Semantic HTML first**: Use `<button>`, `<a>`, `<nav>`, `<main>`, `<ul>` etc. before reaching for ARIA. ARIA is a last resort.
- [ ] **Landmarks**: Page has `<header>`, `<nav>`, `<main>`, `<footer>` landmarks; one `<main>` per page.
- [ ] **Live regions**: Dynamic updates (toasts, async results) use `aria-live` (`polite` for most, `assertive` for urgent).
- [ ] **Name/Role/Value**: Custom widgets expose correct `role`, accessible name, and state (`aria-expanded`, `aria-checked`, `aria-selected`).

## ARIA Quick Reference

| Pattern | Key attributes |
|---|---|
| Toggle button | `aria-pressed` |
| Disclosure / accordion | `aria-expanded`, `aria-controls` |
| Tabs | `role="tablist"`, `role="tab"`, `aria-selected`, `role="tabpanel"` |
| Dialog / modal | `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, focus trap |
| Menu | `role="menu"`, `role="menuitem"`, arrow-key navigation |
| Combobox | `role="combobox"`, `aria-expanded`, `aria-activedescendant` |
| Alert / toast | `role="alert"` or `aria-live="assertive"` |
| Status | `role="status"` or `aria-live="polite"` |
| Loading | `aria-busy="true"` |

## Testing Tools

- **axe-core / @axe-core/react**: Automated a11y checks in dev; flags contrast, missing labels, ARIA misuse.
- **eslint-plugin-jsx-a11y**: Catches common issues at lint time.
- **Keyboard-only pass**: Unplug the mouse. Tab through the whole page; confirm every action is reachable and focus is always visible.
- **Screen reader**: Test with VoiceOver (macOS: Cmd+F5), NVDA (Windows), or TalkBack (Android). Confirm content, structure, and state are announced.
- **Lighthouse / Chrome DevTools**: Accessibility audit and contrast checker.
- **Browser zoom**: Test at 200% and 400% zoom for reflow.

> Automated tools catch ~30–40% of issues. Manual keyboard and screen-reader passes are mandatory.

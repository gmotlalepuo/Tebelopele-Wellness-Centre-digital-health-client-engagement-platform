# Design System

## Identity

The supplied Tebelopele wordmark combines a deep plum name with an orange sunrise and gold rays. Product surfaces use a restrained palette: white and plum-tinted neutrals carry most of the interface, plum establishes identity and selection, and sunrise orange/gold marks important actions and moments of warmth.

## Color

All implementation tokens use OKLCH. Source-logo sampling anchors the brand near `#732273`, `#F5A55E` and `#F0C46D`; production tokens adjust lightness where necessary to meet contrast requirements.

- `--brand`: deep plum for primary actions, navigation and focus.
- `--brand-strong`: darker plum for hover and high-contrast text.
- `--sun`: accessible burnt orange for meaningful highlights.
- `--gold`: supporting accent for small visual details.
- `--background`: near-white neutral with a slight plum tint.
- `--surface`: true white.
- `--ink`: near-black plum for body text.
- Semantic success, warning, danger and information colors are independent of brand accents.

Do not use gradients for text or general surfaces. Status must never rely on color alone.

## Typography

Use Geist Sans throughout the product interface. Headings are compact and calm, with balanced wrapping and letter spacing no tighter than `-0.03em`. Body content is limited to approximately 70 characters per line where prose is read continuously. Data interfaces may be denser.

## Shape and elevation

Controls use an 8–10px radius; bounded content regions use 12–16px. Prefer spacing, background changes and a single border over wide decorative shadows. Pills are reserved for compact status or filtering controls.

## Layout

The public shell uses a concise header and wide readable content column. Authenticated client and staff areas use a stable sidebar on larger screens and a compact top navigation on smaller screens. Responsive changes alter structure rather than shrinking typography. Minimum interactive target size is 44px.

## Components and states

Buttons, links, fields, navigation items, alerts and status indicators must include default, hover, focus-visible, active, disabled, loading and error behavior where applicable. Pages include useful loading, empty and error states. Skeletons represent content loading; short button operations use an inline progress label.

## Motion

Use 150–220ms transitions for hover, focus and disclosure state. Motion communicates state only. Respect `prefers-reduced-motion` and do not gate visibility behind animation.

## Accessibility

Target WCAG 2.2 AA. Maintain 4.5:1 contrast for body and placeholder text, use semantic landmarks and headings, preserve logical focus order, expose errors programmatically and pair icons with accessible names when their meaning is not already in visible text.

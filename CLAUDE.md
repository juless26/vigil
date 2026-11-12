# Vigil design system rules

Vigil is for mothers recovering from opioid use disorder and the NICU nurses who support them during holding sessions. Screens must be calm, easy to read, and respectful. These rules match the "How to use this library" panel in Figma.

## Build only from what exists

- Build every screen from the components in `Sources/VigilDesignSystem/Components`, plus standard SwiftUI navigation, tab bars, lists and segmented pickers.
- If a screen needs something that is not there, add the component to Figma and to this package at the same time, with its variants, before using it. Do not invent one-off views.
- Each component's options are closed enums. Use only the cases that exist, such as `VigilStatus.checkNow`, `.checkSoon`, `.holding` and `.notHolding`.

## Tab bar

The nurse app has four tabs, in this order, using these SF Symbols. iOS fills the selected one automatically.

| Tab | SF Symbol |
|---|---|
| Patients | `person.2` |
| Alerts | `bell` (`bell.badge` when an alert is waiting) |
| Unit | `chart.bar` |
| Settings | `gear` |

## Color

- Use `VigilToken` for component colors and `VigilColor` for screen colors. Never write a hex value or a system color like `.red` on a screen.
- Every text and background pair passes WCAG AA at 4.5 to 1 in light and dark mode. On the phone, orange and pink appear only as dots, edges and bars, never as small text.
- On the watch, small text can use `VigilToken.Watch.accent`, because the watch pink on black passes at 11.8 to 1. Other pinks and oranges still stay out of watch text.
- Do not add brown, beige or gray. The neutrals are tinted blue (`ink` and `mist`).

## Accessibility

- Every tappable element is at least 44 pt tall (`VigilLayout.Size.touchMin`). Buttons come in Large (50 pt) and Medium (44 pt) only.
- Use system text styles (`.headline`, `.body`, `.footnote`) so text grows with Dynamic Type.
- Status always shows a word next to its color.
- Give every row a single VoiceOver label that reads name, status and detail.
- Check-now alerts post a VoiceOver announcement and stay on screen until a nurse acts.

## Words

- Alerts describe what the watch measured, not the mother. Write "The watch vibrated twice and Malika has not responded", not "Malika fell asleep again".
- Lists show what is happening now. Keep date of birth, diagnosis and medication off any screen a passerby could read.
- Use sentence case and US spelling.

## Code Connect

- Each Figma component has a template in `figma/`. When you change a component's API, update its template in the same commit.
- Templates are `.figma.ts` files using `figma.code`. Map every Figma variant value.

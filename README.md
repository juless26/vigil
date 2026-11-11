# Vigil

Vigil helps NICU nurses keep holding sessions safe for mothers recovering from opioid use disorder. It has two apps: a nurse app on iPhone and a mother's app on Apple Watch.

This repository holds the shared design system, `VigilDesignSystem`, as a Swift package. Both apps use it. The same components live in the Vigil Figma file on the "Vigil Design System" page, and Code Connect links each Figma component to its Swift code.

## What is here

| Folder | What it holds |
|---|---|
| `Sources/VigilDesignSystem/Tokens` | Colors in three tiers, plus spacing and sizes |
| `Sources/VigilDesignSystem/Components` | The nine SwiftUI components |
| `figma` | One Code Connect template per Figma component |

### Color tiers

These match the four variable collections in Figma.

| Swift | Figma collection | Example |
|---|---|---|
| `VigilPrimitive` | Vigil Primitives | `blue600`, `ink950` |
| `VigilColor` | Vigil Color (Light, Dark) | `textSecondary`, `statusCheckNow` |
| `VigilToken` | Vigil Component | `VigilToken.Badge.background(.checkNow)` |
| `VigilLayout` | Vigil Layout | `VigilLayout.Size.touchMin` |

Screens use `VigilToken` and `VigilLayout` only. Apple Watch always uses the dark values.

### Components

| Swift | Figma component |
|---|---|
| `StatusBadge` | Status Badge |
| `VigilButton` | Button |
| `PatientRow` | Patient Row |
| `AlertCard` | Alert Card |
| `VitalRow` | Vital Row |
| `MetricTile` | Metric Tile |
| `FormTextRow`, `FormPickerRow` | Form Row |
| `SectionHeader` | Section Header |
| `ChevronIcon` | Icon / Chevron Right |

## Open the package in Xcode

1. Open Xcode.
2. Choose File → Open, and pick this folder.
3. Open any file in `Components` and press Option-Command-Return to see its preview.

## Turn on Code Connect

You do these steps once. Code Connect then shows the Swift code for any selected component in Figma Dev Mode.

1. Publish the Figma library. In the Vigil file, open the Assets tab, click the book icon, and click Publish under "This file".
2. Make a Figma access token. In Figma, open Settings → Security → Personal access tokens. Click "Generate new token", give it Code Connect write access and File content read access, and copy it.
3. Open Terminal and go to this folder:
   ```
   cd path/to/vigil
   ```
4. Install the Code Connect tool:
   ```
   npm install
   ```
5. Publish the templates, pasting your token where it says YOUR_TOKEN:
   ```
   npx figma connect publish --token=YOUR_TOKEN
   ```
6. In Figma, switch to Dev Mode and select a Status Badge. The Code panel shows `StatusBadge(status: .checkNow)`.

If step 5 says the Code Connect scope is missing, the token was made without Code Connect write access. Make a new token and check that box. If the box does not appear, your Figma plan or seat does not include Code Connect.

## Rules

The rules in `CLAUDE.md` and on the "Vigil Design System" Figma page are the same. Follow them for any new screen.

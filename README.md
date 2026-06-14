# Vision Board ✨

A personal vision board web app built with Flutter Web. Images and text cards are scattered across the screen in a collage style — fully interactive and persistent. The board lives inside a retro handheld game console frame.

Built as a side project to learn Flutter, coming from a Python/AI background.

---

## Features

### Game Console UI (NEW in v1.5)
- Entire screen wrapped in a handheld console frame — header bar, screen bezel, button panel
- Console colors fully re-skin per mood (device body, screen border, button colors, accent, text)
- Top header: console logo, current mood badge, selected card indicator, blinking LED
- Bottom panel: mood-select buttons + D-PAD + action buttons (UPLOAD / TEXT / BG / SAVE / PNG / RESET)
- 3D physical buttons — layered surface + side faces, surface depresses on press via `AnimatedPositioned`
- 3D D-PAD — moves the selected card by small increments per tap

### Card Selection — Spotlight + Focus
- Tapping a card dims all other cards (~65% darker) to spotlight the selection
- Selected card scales up slightly with an accent-colored glow border
- Edit handles (move/resize/rotate/delete/reorder) appear around the selected card
- D-PAD nudges the selected card's position without dragging

### Board
- Polaroid-style photo cards with random sizes and rotations
- 14 text card styles: Torn, Ripped, Notebook, Float, Stamp, Script + 8 special effects
- Special effects: ⚡ Neon (animated flicker), 🌈 Hologram, 🫧 Bubble, ⬜ Outline, 🎮 Retro, 👾 Glitch, 🪞 Chrome, 🌈 Rainbow
- Overlap-prevention algorithm for natural collage layout
- Google Fonts (Playfair Display, Dancing Script)
- Single screen — no scrolling

### Mood System
- 5 mood themes: ✨ Manifestation, 🌿 Soft Life, 💪 That Girl, 🌀 Cyber Dream, 🌍 Wanderlust
- Each mood applies matching images, text cards, effects, colors, console skin, and background in one tap
- Random background image selected from a per-mood asset pool on each apply
- Per-mood intro animations — each mood feels completely different on load
- Per-mood floating speed and neon flicker intensity

### Mood Animations
| Mood | Intro Style |
|------|------------|
| ✨ Manifestation | Cards fly in from all directions and slam into place |
| 🌿 Soft Life | Cards fall from above like leaves, swaying gently |
| 💪 That Girl | Cards snap into place column by column, left to right |
| 🌀 Cyber Dream | Cards glitch between random positions before locking in |
| 🌍 Wanderlust | Cards rise from below through mist, fading in softly |

### Editing
- **Drag** any card to reposition
- **Tap** to select — spotlight effect + edit handles
- **D-PAD** to nudge the selected card
- **Double tap** text cards to edit content, style, and color
- **Resize** cards by dragging the bottom-right handle
- **Rotate** cards by dragging the bottom-left handle
- **Layer** cards forward/backward with top-left arrows
- **Delete** cards with the top-right red button
- **Upload** images from your computer
- **Add** custom text cards with live preview
- **Reset** board to original state

### Background
- 6 pattern types: Solid, Gradient (2–3 colors), Dots, Lines, Grid, Crosshatch
- 12 built-in presets (Black, Dark Blue, Midnight, Forest, Rose, White, Cream...)
- Full color picker for each color slot
- Adjustable pattern size via slider
- Upload a custom background image
- Mood-matched background images (asset-based, randomly selected)
- Real-time preview in the dialog
- Background persists across sessions

### Animation
- Per-mood intro animations — 5 distinct styles
- Floating ambient animation — speed and amplitude vary by mood
- Neon flicker — intensity varies by mood (Cyber Dream flickers most aggressively)
- Spotlight + select-scale animations for card focus
- 5 animation controllers total — no lag

### Export
- Export board as high-quality PNG (2x pixel ratio) via browser download

### Persistence
- All cards, positions, styles, and background saved to browser localStorage
- Uploaded images encoded as base64 and persisted across sessions
- Fully responsive — card positions stored as ratios, not pixels

---

## Tech Stack

- Flutter Web
- Dart
- `google_fonts`
- `shared_preferences`
- `file_picker`
- `flutter_colorpicker`
- `CustomPainter` for torn paper effects and background patterns
- `BackdropFilter` for bubble glass effect
- `ShaderMask` for hologram and chrome effects
- `dart:html` for PNG download

---

## Getting Started

```bash
git clone https://github.com/YOUR_USERNAME/Vision-Board-.git
cd Vision-Board-
flutter pub get
flutter run -d chrome
```

---

## Project Structure

```
Vision-Board-/
├── lib/
│   └── main.dart              # All UI and logic
├── imgs/
│   ├── Manifestation/         # Personal images (not tracked in git)
│   ├── soft_life/
│   ├── That_Girl/
│   ├── Cyber_Dream/
│   └── wanderlust/
├── background/
│   ├── Manifestation/         # Mood background images (not tracked in git)
│   ├── soft_life/
│   ├── That_Girl/
│   ├── Cyber_Dream/
│   └── wanderlust/
├── pubspec.yaml
└── README.md
```

---

## Roadmap

### v1.0 — Done
- [x] Collage layout with overlap prevention
- [x] Polaroid photo cards
- [x] Torn paper text cards (6 styles)
- [x] Center-pinned focal image

### v1.1 — Done
- [x] Save board state with `shared_preferences`
- [x] Upload images from computer (`file_picker`)
- [x] Add / edit / delete text cards
- [x] Drag to reposition cards
- [x] Resize cards
- [x] Rotate cards
- [x] Layer ordering (bring forward / send backward)
- [x] Reset board

### v1.3 — Done
- [x] Sticker-drop intro animation with custom curve
- [x] Floating ambient animation (sin wave, per-card phase offset)
- [x] Responsive layout — ratio-based card positions
- [x] Animation performance — 40 controllers → 3
- [x] 8 special text effects (Neon, Hologram, Bubble, Outline, Retro, Glitch, Chrome, Rainbow)
- [x] Neon flicker animation
- [x] Background customization (solid, gradient, patterns, image upload)
- [x] Export board as PNG

### v1.4 — Done
- [x] 5 mood themes (Manifestation, Soft Life, That Girl, Cyber Dream, Wanderlust)
- [x] Per-mood image sets, text presets, color palettes, and background images
- [x] Per-mood intro animations (5 distinct styles)
- [x] Per-mood floating speed and neon flicker intensity
- [x] Random background image selection from mood asset pool
- [x] Asset-based background image support alongside user-uploaded images

### v1.5 — Done
- [x] Full game console UI — header, screen bezel, button panel (re-skins per mood)
- [x] 3D physical buttons with press animation (layered surface + side, `AnimatedPositioned`)
- [x] 3D D-PAD for nudging selected card position
- [x] Card selection spotlight (dim other cards) + select-scale + glow border
- [x] Game console UI added

### v1.6 — Next
- [ ] Console "glow" polish — screen shimmer/shine effect, more 3D depth on bezel and buttons
- [ ] Floating decorative elements (bubbles drifting across the screen)
- [ ] Per-mood button depth variation (e.g. That Girl = shallow/minimal, Cyber Dream = deep/strong)
- [ ] Quiz flow → mood result → board generation
- [ ] Tap card to zoom in

### v1.7 — Future
- [ ] State management with Riverpod
- [ ] Multiple boards
- [ ] Firebase storage for images
- [ ] Firebase Auth (personal board per user)
- [ ] Background music per mood
- [ ] GIF export (native app)
- [ ] Mobile support (iOS / Android)

---

## Learning Goals

- `StatelessWidget` vs `StatefulWidget`
- `Stack` + `Positioned` for free layout
- `CustomPainter` for custom drawing (torn paper, background patterns)
- `GestureDetector` for drag / tap / double tap
- `LayoutBuilder` for responsive sizing
- `AnimationController` + custom `Curve` for sticker physics
- `ShaderMask` + `BackdropFilter` for visual effects
- `shared_preferences` for local persistence
- `file_picker` for file uploads
- `RepaintBoundary` for image export
- `dart:html` for browser download
- Ratio-based layout for window resize support
- Per-mood animation system with distinct intro styles
- Layered `Stack` + `AnimatedPositioned` for 3D button press effects

---

## Notes

Images in `imgs/` and `background/` are personal and not tracked in git (see `.gitignore`).
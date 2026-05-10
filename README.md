# Vision Board ✨

A personal vision board web app built with Flutter Web. Images and text cards are scattered across the screen in a collage style — fully interactive and persistent.

Built as a side project to learn Flutter, coming from a Python/AI background.

---

## Features

### Board
- Polaroid-style photo cards with random sizes and rotations
- 14 text card styles: Torn, Ripped, Notebook, Float, Stamp, Script + 8 special effects
- Special effects: ⚡ Neon (animated flicker), 🌈 Hologram, 🫧 Bubble, ⬜ Outline, 🎮 Retro, 👾 Glitch, 🪞 Chrome, 🌈 Rainbow
- Center-pinned focal image
- Overlap-prevention algorithm for natural collage layout
- Google Fonts (Playfair Display, Dancing Script)
- Single screen — no scrolling

### Editing
- **Drag** any card to reposition
- **Tap** to select — shows edit handles
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
- **Upload a custom background image**
- Real-time preview in the dialog
- Background persists across sessions

### Animation
- Sticker-drop intro animation — cards appear one by one with a custom bounce curve
- Floating ambient animation — cards gently drift after landing
- Neon flicker — neon text cards pulse continuously
- 3 animation controllers total (previously 40) — no lag

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
│   └── main.dart         # All UI and logic
├── imgs/                 # Vision board images (not tracked in git)
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

### v1.4 — Next
- [ ] Tap card to zoom in
- [ ] State management with Riverpod
- [ ] Multiple boards

### v1.5 — Future
- [ ] Firebase storage for images
- [ ] Firebase Auth (personal board per user)
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

---

## Notes

Images in `imgs/` are personal and not tracked in git (see `.gitignore`).
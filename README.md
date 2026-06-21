# Vision Board ✨

A personal vision board web app built with Flutter Web. Images and text cards are scattered across the screen in a collage style — fully interactive and persistent. The board lives inside a retro handheld game console frame.

Built as a side project to learn Flutter, coming from a Python/AI background.

---

## Features

### Game Console UI
- Entire screen wrapped in a handheld console frame — header bar, screen bezel, button panel
- Console colors fully re-skin per mood (device body, screen border, button colors, accent, text)
- Top header: console logo, current mood badge, selected card indicator, blinking LED (synced to mood particle color)
- Bottom panel: mood-select buttons + D-PAD + action buttons (UPLOAD / TEXT / BG / SAVE / PNG / RESET)
- 3D physical buttons — layered surface + side faces, surface depresses on press via `AnimatedPositioned`, with a subtle scanline texture on the surface
- 3D D-PAD — moves the selected card by increments; **hold to repeat** for continuous movement

### Ambient Particle Layer (NEW in v1.6)
- Floating sparkle/bubble particles drift across the entire board, above the cards
- Fully re-styled per mood — color, shape (star / bubble / dust), count, and size all change
- Each mood has a distinct **motion pattern**, not just a different look:

| Mood | Particle Style | Motion |
|------|----------------|--------|
| ✨ Manifestation | Purple stars | Radiate outward from center, pulse and reset |
| 🌿 Soft Life | Beige bubbles | Slow horizontal drift, gentle rise |
| 💪 That Girl | Gold dust | Nearly still, minimal micro-shimmer |
| 🌀 Cyber Dream | Cyan stars | Zigzag + sudden glitch-teleport |
| 🌍 Wanderlust | Blue bubbles | Wide swirling drift while rising (fog-like) |

### Mood Transition Effect (NEW in v1.6)
- Switching moods triggers a "cartridge swap" transition: the screen briefly dims to near-black with an accent-colored scanline sweeping top to bottom, then the new board fades back in
- Cards and background are swapped at the dim's peak, so the change itself is hidden inside the blackout
- Header LED color and screen bezel glow are tied to the active mood's particle color for a cohesive look

### Card Selection — Spotlight + Focus
- Tapping a card dims all other cards (~65% darker) to spotlight the selection
- Selected card does an elastic pulse-scale on selection (bouncy, not just a flat zoom) with an accent-colored glow border
- Edit handles (move/resize/rotate/delete/reorder) appear around the selected card
- D-PAD nudges the selected card's position without dragging — tap once to nudge, hold to move continuously

### Card Interactions (NEW in v1.6)
- **Drag to lift**: picking up a card scales it up, lifts it slightly, and deepens its drop shadow — released cards settle back down smoothly
- **Spawn animation**: newly uploaded images or newly added text cards pop in with an elastic "ejected from the console" entrance (rises and bounces into place) instead of just appearing
- **Save pulse**: pressing SAVE triggers a quick LED flicker in the header and a glowing pulse around the screen bezel, giving visible confirmation that the board was written to storage

### Board
- Polaroid-style photo cards with random sizes and rotations
- 14 text card styles: Torn, Ripped, Notebook, Float, Stamp, Script + 8 special effects
- Special effects: ⚡ Neon (animated flicker), 🌈 Hologram, 🫧 Bubble, ⬜ Outline, 🎮 Retro, 👾 Glitch, 🪞 Chrome, 🌈 Rainbow
- Overlap-prevention algorithm for natural collage layout
- Google Fonts (Playfair Display, Dancing Script)
- Single screen — no scrolling

### Mood System
- 5 mood themes: ✨ Manifestation, 🌿 Soft Life, 💪 That Girl, 🌀 Cyber Dream, 🌍 Wanderlust
- Each mood applies matching images, text cards, effects, colors, console skin, particles, and background in one tap
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
- **Drag** any card to reposition (with lift effect)
- **Tap** to select — spotlight effect + pulse + edit handles
- **D-PAD** to nudge the selected card (tap or hold)
- **Double tap** text cards to edit content, style, and color
- **Resize** cards by dragging the bottom-right handle
- **Rotate** cards by dragging the bottom-left handle
- **Layer** cards forward/backward with top-left arrows
- **Delete** cards with the top-right red button
- **Upload** images from your computer (with spawn-in animation)
- **Add** custom text cards with live preview (with spawn-in animation)
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
- Spotlight + elastic select-pulse animations for card focus
- Ambient particle system with per-mood motion patterns
- Mood transition blackout + scanline sweep
- Drag-lift, spawn-in, and save-pulse micro-interactions
- 8 animation controllers total — still no lag

### Export
- Export board as high-quality PNG (2x pixel ratio) via browser download
- Particle layer is included in the exported image (selection UI is hidden first)

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
- `CustomPainter` for torn paper effects, background patterns, particles, and transition scanlines
- `BackdropFilter` for bubble glass effect
- `ShaderMask` for hologram and chrome effects
- `dart:async` (`Timer` / `Timer.periodic`) for D-PAD hold-to-repeat
- `dart:html` for PNG download

---

## Getting Started

```bash
git clone https://github.com/YOUR_USERNAME/Vision-Board-.git
cd Vision-Board-
flutter pub get
flutter run -d chrome
```

> If something looks stale after pulling new code (old assets, missing effects), run `flutter clean && flutter pub get` before `flutter run` — incremental build caches can get out of sync.

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

### v1.6 — Done
- [x] Ambient particle layer with per-mood color, shape, and motion pattern (radiate / drift / still / glitch / swirl)
- [x] Mood transition blackout + scanline sweep ("cartridge swap" feel)
- [x] Header LED synced to mood particle color
- [x] Button surface scanline texture for retro device feel
- [x] Drag-to-lift card interaction (scale up, lift, deepen shadow while dragging)
- [x] Spawn-in animation for newly added cards (elastic pop-in with rise)
- [x] D-PAD hold-to-repeat for continuous card movement
- [x] Save pulse — LED flicker + bezel glow on save confirmation
- [x] Elastic pulse-scale on card selection (replacing flat scale)
- [x] Fixed mismatched `.png`/`.jpg` asset references causing 404s

### v1.7 — Next
- [ ] Console "glow" polish — additional screen shimmer/shine effect
- [ ] Per-mood button depth variation (e.g. That Girl = shallow/minimal, Cyber Dream = deep/strong)
- [ ] Quiz flow → mood result → board generation
- [ ] Tap card to zoom in

### v1.8 — Future
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
- `CustomPainter` for custom drawing (torn paper, background patterns, particles, scanlines)
- `GestureDetector` for drag / tap / double tap / pan-start / pan-end
- `LayoutBuilder` for responsive sizing
- `AnimationController` + custom `Curve` for sticker physics and elastic pulses
- `ShaderMask` + `BackdropFilter` for visual effects
- `shared_preferences` for local persistence
- `file_picker` for file uploads
- `RepaintBoundary` for image export
- `dart:html` for browser download
- `dart:async` `Timer` / `Timer.periodic` for press-and-hold repeat behavior
- Ratio-based layout for window resize support
- Per-mood animation system with distinct intro styles and particle motion
- Layered `Stack` + `AnimatedPositioned` for 3D button press effects
- Debouncing rapid state writes (D-PAD hold) before persisting to storage

---

## Notes

Images in `imgs/` and `background/` are personal and not tracked in git (see `.gitignore`).

If you rename or convert image files (e.g. `.jpg` → `.png`), double check every reference to that filename in `main.dart` — Flutter Web will fail silently in the console with a 404 if the extension doesn't match exactly.
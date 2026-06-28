# Vision Board ✨

A personal vision board web app built with Flutter Web. Images and text cards are scattered across the screen in a collage style — fully interactive and persistent. The board lives inside a retro handheld game console frame styled after Claude Design.

Built as a side project to learn Flutter, coming from a Python/AI background.

---

## Features

### Game Console UI (Claude Design–based)
- Entire screen wrapped in a handheld console frame — shell gradient body, screen bezel, button panel
- Console body uses a 3-stop linear gradient (`shellHi → shell1 → shell2`) + plastic sheen overlay + 4 radial-gradient screws — same structure as the Claude Design HTML source
- Console colors fully re-skin per mood (body, bezel, buttons, accent, text)
- Top header: `VISION BOARD` logo, current mood pill badge, blinking LED (synced to mood particle color)
- Bottom panel: mood pill buttons + 3D D-PAD + action buttons (UPLOAD / TEXT / BG / SAVE / PNG / RST)
- 3D physical buttons — layered side + surface with `AnimatedPositioned` press, scanline texture on surface, `shellHi → btnFace` gradient
- 3D D-PAD — radial-gradient center orb + hold-to-repeat for continuous card movement

### Ambient Particle System (HTML source–ported)
- Floating particles rendered on a `CustomPainter` canvas above the cards
- Particle logic ported directly from the Claude Design HTML `drawParticles()` function — same types, counts, movement, and render style:

| Mood | Type | Count | Behaviour |
|------|------|-------|-----------|
| ✨ Manifestation | `star` | 72 | 8-point stars float upward, purple/pink/white mix, twinkle |
| 🌿 Soft Life | `dust` | 46 | Large soft circles drift slowly in all directions |
| 💪 That Girl | `gold` | 30 | Gold stars float upward slowly, minimal |
| 🌀 Cyber Dream | `glitch` | 58 | Thin rectangles flicker at random positions, cyan/pink |
| 🌍 Wanderlust | `bubble` | 34 | Circles rise with sideways wobble, accent2 highlight dot |

### Screen Effects
- **Bloom** — `BlendMode.screen` radial gradient from accent color (matches HTML `mix-blend-mode: screen`)
- **Vignette** — `RadialGradient` inset darkening at screen edges only
- **Glass reflection** — subtle white gradient across the top 80px of the screen
- **Grain** (Manifestation / Soft Life) — fine dot overlay via CSS-matched opacity vars

### Mood Transition
- Switching moods triggers a "cartridge swap": screen dims to near-black with an accent scanline sweeping top → bottom, content swaps at the peak, then fades back in
- Transition painter sits above `RepaintBoundary` (visible over cards and controls)
- Forward duration 350ms, reverse 500ms — asymmetric for a snappier feel

### Card Selection — Spotlight + Focus
- Tapping a card dims all other cards (~65%) to spotlight the selection
- Selected card does an `elasticOut` pulse-scale on tap with an accent glow border
- Edit handles (delete / reorder / resize / rotate) appear around the selected card
- D-PAD nudges the selected card — tap for one step, hold for continuous movement

### Card Interactions
- **Drag to lift** — card scales up 1.22×, rises 10px, casts a deeper shadow while dragging
- **Spawn-in** — newly added cards pop in from below with an `elasticOut` bounce
- **Save pulse** — SAVE press triggers LED flicker + bezel glow ring

### Board
- Polaroid-style photo cards — `cardFrame` color frame matching active mood, mood-specific caption labels
- 14 text card styles: Torn, Ripped, Notebook, Float, Stamp, Script + 8 special effects
- Special effects: ⚡ Neon (animated flicker), 🌈 Hologram, 🫧 Bubble, ⬜ Outline, 🎮 Retro, 👾 Glitch, 🪞 Chrome, 🌈 Rainbow
- Overlap-prevention layout algorithm
- Google Fonts (Playfair Display, Dancing Script)
- Single screen — no scrolling

### Mood System
- 5 themes: ✨ Manifestation, 🌿 Soft Life, 💪 That Girl, 🌀 Cyber Dream, 🌍 Wanderlust
- Each mood applies images, text cards, colors, console skin, particles, and background in one tap
- Random background image from per-mood asset pool on each apply
- Per-mood intro animations, float speed, and neon flicker intensity

### Mood Animations
| Mood | Intro Style |
|------|------------|
| ✨ Manifestation | Cards fly in from all directions and slam into place |
| 🌿 Soft Life | Cards fall from above like leaves, swaying gently |
| 💪 That Girl | Cards snap into place column by column |
| 🌀 Cyber Dream | Cards glitch between random positions before locking in |
| 🌍 Wanderlust | Cards rise from below through mist |

### Export
- Export board as PNG at 2× pixel ratio via browser download
- Particles included in export; selection UI hidden before capture

### Persistence
- Cards, positions, styles, and background saved to browser localStorage
- Uploaded images encoded as base64 and persisted across sessions
- Ratio-based card positions — responsive to window resize

---

## Tech Stack

- Flutter Web / Dart
- `google_fonts`, `shared_preferences`, `file_picker`, `flutter_colorpicker`
- `CustomPainter` — torn paper, backgrounds, particles (HTML-ported logic), scanline transitions, bloom
- `BackdropFilter` — bubble glass effect
- `ShaderMask` — hologram and chrome effects
- `BlendMode.screen` — bloom overlay matching CSS `mix-blend-mode: screen`
- `dart:async` `Timer` / `Timer.periodic` — D-PAD hold-to-repeat
- `dart:html` — PNG download

---

## Getting Started

```bash
git clone https://github.com/likecola/Vision-Board-.git
cd Vision-Board-
flutter pub get
flutter run -d chrome
```

> If effects look stale after pulling, run `flutter clean && flutter pub get` first — incremental build caches can get out of sync.

---

## Project Structure

```
Vision-Board-/
├── lib/
│   └── main.dart
├── imgs/
│   ├── Manifestation/
│   ├── soft_life/
│   ├── That_Girl/
│   ├── Cyber_Dream/
│   └── wanderlust/
├── background/
│   ├── Manifestation/
│   ├── soft_life/
│   ├── That_Girl/
│   ├── Cyber_Dream/
│   └── wanderlust/
├── pubspec.yaml
└── README.md
```

Images in `imgs/` and `background/` are personal and not tracked in git.

---

## Roadmap

### v1.0–v1.4 — Done
- [x] Collage layout, polaroid cards, text cards (14 styles), overlap prevention
- [x] Drag / resize / rotate / layer / delete / upload / reset
- [x] Save + export PNG, background customization
- [x] 5 mood themes with per-mood images, text, colors, backgrounds
- [x] Per-mood intro animations (5 distinct styles)

### v1.5 — Done
- [x] Game console UI frame (header, bezel, button panel)
- [x] 3D buttons with press animation
- [x] D-PAD card nudge
- [x] Card selection spotlight + glow

### v1.6 — Done
- [x] Ambient particle layer (per-mood motion patterns)
- [x] Mood transition blackout + scanline sweep
- [x] LED + bezel save pulse
- [x] Drag-to-lift, spawn-in animations
- [x] D-PAD hold-to-repeat
- [x] Elastic card selection pulse

### v1.7 — Done
- [x] Full Claude Design UI port — shell gradient body, plastic sheen, radial screws
- [x] Particle system ported from HTML source (star / dust / gold / glitch / bubble)
- [x] `BlendMode.screen` bloom matching CSS `mix-blend-mode: screen`
- [x] Mood transition moved above `RepaintBoundary` (now visible over all layers)
- [x] Mood pill buttons with glow on active
- [x] D-PAD center orb with radial gradient + pulse animation
- [x] Action button layout fixed (D-PAD left, actions center + right)
- [x] Polaroid cards with mood-matched `cardFrame` color and caption labels

### v1.8 — Next
- [ ] Quiz flow → mood result → board generation
- [ ] Per-mood button depth variation
- [ ] Tap card to zoom in
- [ ] Screen shimmer / CRT scanline overlay (Cyber Dream)

### v1.9 — Future
- [ ] Riverpod state management
- [ ] Multiple boards
- [ ] Firebase storage + Auth
- [ ] Background music per mood
- [ ] Mobile support (iOS / Android)

---

## Notes

If you rename or convert image files (e.g. `.jpg` → `.png`), update every reference in `main.dart` — Flutter Web returns a 404 silently if the extension doesn't match.
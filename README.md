# Vision Board ✨

A personal vision board web app built with Flutter Web. Images and text cards are scattered across the screen in a collage style — like pinning photos to a real board.

Built as a side project to learn Flutter, coming from a Python/AI background.

---

## Preview

Dark, luxe aesthetic with polaroid-style photo cards and torn paper text cards arranged freely on screen.

---

## Features

- Polaroid-style photo cards with random sizes and rotations
- 4 text card styles: torn paper, heavily torn, notebook paper, text-only
- Center-pinned focal image
- Overlap-prevention algorithm for natural collage layout
- Google Fonts (Playfair Display)
- Single screen — no scrolling

---

## Tech Stack

- Flutter Web
- Dart
- Google Fonts (`google_fonts`)
- CustomPainter for torn paper effect

---

## Getting Started

### Prerequisites

- Flutter SDK
- Chrome browser

### Run locally

```bash
git clone https://github.com/YOUR_USERNAME/vision_board.git
cd vision_board
flutter pub get
flutter run -d chrome
```

---

## Project Structure

```
vision_board/
├── lib/
│   └── main.dart         # All UI logic
├── imgs/                 # Vision board images (not tracked in git)
├── pubspec.yaml
└── README.md
```

---

## Roadmap

### v1.0 — Current
- [x] Collage layout with overlap prevention
- [x] Polaroid photo cards
- [x] Torn paper text cards (4 styles)
- [x] Center-pinned focal image

### v1.1 — Persistence
- [ ] Save board state with `shared_preferences`
- [ ] Board persists after browser refresh

### v1.2 — Interactivity
- [ ] Drag and drop cards to reposition
- [ ] Add / delete images from UI
- [ ] Add / edit text cards from UI
- [ ] Resize cards

### v1.3 — Polish
- [ ] Animation when board loads (cards fly in)
- [ ] Tap card to zoom in
- [ ] Long press to delete

### v1.4 — Advanced Flutter
- [ ] State management with Riverpod
- [ ] Firebase storage for images
- [ ] Firebase Auth (personal board per user)
- [ ] Export board as image

### Future
- [ ] Mobile support (iOS / Android)
- [ ] Multiple boards

---

## Learning Goals

This project is intentionally used to explore Flutter concepts:

- `StatelessWidget` vs `StatefulWidget`
- `Stack` + `Positioned` for free layout
- `CustomPainter` for custom drawing
- `GestureDetector` for drag interactions
- `MediaQuery` for responsive sizing
- State management (setState → Riverpod)
- Local storage → Cloud storage progression

---

## Notes

Images in `imgs/` are personal and not tracked in git (see `.gitignore`).
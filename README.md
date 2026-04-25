# Vision Board ✨

A personal vision board web app built with Flutter Web. Images and text cards are scattered across the screen in a collage style — fully interactive and persistent.

Built as a side project to learn Flutter, coming from a Python/AI background.

---

## Features

### Board
- Polaroid-style photo cards with random sizes and rotations
- 6 text card styles: Torn, Ripped, Notebook, Float, Stamp, Script
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

### Persistence
- Board state saved to browser localStorage via `shared_preferences`
- Uploaded images encoded as base64 and persisted across sessions

---

## Tech Stack

- Flutter Web
- Dart
- `google_fonts`
- `shared_preferences`
- `file_picker`
- `CustomPainter` for torn paper effects

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

### v1.2 — Next
- [ ] Animation when board loads
- [ ] Tap card to zoom in
- [ ] State management with Riverpod

### v1.3 — Future
- [ ] Firebase storage for images
- [ ] Firebase Auth (personal board per user)
- [ ] Export board as image
- [ ] Mobile support (iOS / Android)
- [ ] Multiple boards

---

## Learning Goals

- `StatelessWidget` vs `StatefulWidget`
- `Stack` + `Positioned` for free layout
- `CustomPainter` for custom drawing
- `GestureDetector` for drag / tap / double tap
- `MediaQuery` for responsive sizing
- `shared_preferences` for local persistence
- `file_picker` for file uploads
- Overlay pattern for decoupled UI controls

---

## Notes

Images in `imgs/` are personal and not tracked in git (see `.gitignore`).
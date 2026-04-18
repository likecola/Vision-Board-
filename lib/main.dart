import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: const VisionBoardPage(),
    );
  }
}

/// CustomPainter that draws a torn paper shape.
/// Creates irregular top and bottom edges using Path to simulate torn paper.
class TornPaperPainter extends CustomPainter {
  final Color color;
  final int seed;
  final CardStyle style;

  TornPaperPainter({
    required this.color,
    required this.seed,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);

    if (style == CardStyle.textOnly) return;

    final paint = Paint()..color = color;
    final path = Path();

    if (style == CardStyle.lined) {
      // Draw notebook background
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // Red margin line
      final redPaint = Paint()
        ..color = const Color(0xFFFF9999).withOpacity(0.6)
        ..strokeWidth = 1.5;
      canvas.drawLine(const Offset(28, 0), Offset(28, size.height), redPaint);

      // Blue horizontal lines
      final linePaint = Paint()
        ..color = const Color(0xFF99BBDD).withOpacity(0.5)
        ..strokeWidth = 0.8;
      double lineY = 20;
      while (lineY < size.height) {
        canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), linePaint);
        lineY += 18;
      }

      // Torn edges at top and bottom
      final tearPaint = Paint()..color = const Color(0xFF0a0a0a);
      final topPath = Path();
      topPath.moveTo(0, 0);
      double x = 0;
      while (x < size.width) {
        x += 5 + rng.nextDouble() * 7;
        topPath.lineTo(x.clamp(0, size.width), rng.nextDouble() * 10);
      }
      topPath.lineTo(size.width, 0);
      topPath.close();
      canvas.drawPath(topPath, tearPaint);

      final botPath = Path();
      botPath.moveTo(0, size.height);
      x = 0;
      while (x < size.width) {
        x += 5 + rng.nextDouble() * 7;
        botPath.lineTo(
          x.clamp(0, size.width),
          size.height - rng.nextDouble() * 10,
        );
      }
      botPath.lineTo(size.width, size.height);
      botPath.close();
      canvas.drawPath(botPath, tearPaint);
      return;
    }

    // torn / tornMore: draw irregular top and bottom edges
    final roughness = style == CardStyle.tornMore ? 0.25 : 0.15;
    path.moveTo(0, size.height * roughness);

    double xPos = 0;
    while (xPos < size.width) {
      xPos += 4 + rng.nextDouble() * (style == CardStyle.tornMore ? 6 : 8);
      final y = size.height * 0.02 + rng.nextDouble() * size.height * roughness;
      path.lineTo(xPos.clamp(0, size.width), y);
    }

    path.lineTo(size.width, size.height * (1 - roughness));

    xPos = size.width;
    while (xPos > 0) {
      xPos -= 4 + rng.nextDouble() * (style == CardStyle.tornMore ? 6 : 8);
      final y =
          size.height * (1 - roughness * 0.3) +
          rng.nextDouble() * size.height * roughness;
      path.lineTo(xPos.clamp(0, size.width), y);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Card style variants for text cards
enum CardStyle {
  torn, // standard torn paper
  tornMore, // heavily torn paper
  lined, // torn notebook paper with lines
  textOnly, // no background, text with shadow only
}

/// Data model for text cards displayed on the vision board
class TextCard {
  final String text;
  final Color paperColor;
  final double fontSize;
  final bool bold;
  final CardStyle style;

  const TextCard({
    required this.text,
    required this.paperColor,
    this.fontSize = 14,
    this.bold = false,
    this.style = CardStyle.torn,
  });
}

class VisionBoardPage extends StatelessWidget {
  const VisionBoardPage({super.key});

  final List<String> images = const [
    'imgs/0058235e3ebb2729faf21be0403e05df.jpg',
    'imgs/015429bcd1aab1991f004d9ee9fdd3aa.jpg',
    'imgs/1500e1282e7a2875d7066cf3647a9fba.jpg',
    'imgs/2555133c526c260b0468435a6e015014.jpg',
    'imgs/267c84483e854b8c522368366af931d5.jpg',
    'imgs/2bd78ea72b681460f5e66bd58508053a.jpg',
    'imgs/2d39cdb4711cd7d59bd7e2cd6f47a284.jpg',
    'imgs/2e0337bf91f32a6ef1ea696829059b95.jpg',
    'imgs/2fdbfddd084b6fa839c49678121e1373.jpg',
    'imgs/3f9dc2e8a65259a47732248c1c9f7e0f.jpg',
    'imgs/470ff04d04eea0ae117783d12deb3431.jpg',
    'imgs/4f459f0c682cbaf55f08e91a55b381d1.jpg',
    'imgs/56e368e13a4f79c1196a321d0f7eaa9e.jpg',
    'imgs/5ae0ab29aa6572d938dcd58ad06d3518.jpg',
    'imgs/5b13d82833aa572e10b94722afe025cd.jpg',
    'imgs/5b4a5382b47fab34d65dd1eb5f8f3660.jpg',
    'imgs/62722e12b7fd9a21fa15843666d06c35.jpg',
    'imgs/64f589d7e4e6f1288907fef9575332f5.jpg',
    'imgs/820fa7d61221505a529323b7d54e0ad4.jpg',
    'imgs/8570b14f818387643170e52719063036.jpg',
    'imgs/89fd9414c37a076060865cc59231fb97.jpg',
    'imgs/8e90048fbaad09eae2a4d2726c3b693d.jpg',
    'imgs/90281e2309ec2ec0e4a8271c06f326f6.jpg',
    'imgs/917ff1305c11db37c219693aad437d52.jpg',
    'imgs/984d44fa26519c56841468899e30ee1b.jpg',
    'imgs/9e73a6ad113b3189f3ccd34bbcb8edcd.jpg',
    'imgs/b4e4a383ebd0d41c7bb48603132a396a.jpg',
    'imgs/daf20a82e77d072196224d0ea525d13b.jpg',
    'imgs/dce74a4b5684af80207214f5343d963d.jpg',
    'imgs/download.png',
    'imgs/f409f422e30e12fd1b73b2c68a78160e.jpg',
    'imgs/f6fbfd0d0714a01e3504d751dc1c6b29.jpg',
    'imgs/fd67b28749505d645c4c7eb279124f9e.jpg',
    'imgs/fd88e0b4103cb45944cc27d6a48207b8.jpg',
  ];

  final List<TextCard> textCards = const [
    TextCard(
      text: 'DREAM BIG',
      paperColor: Color(0xFFF5F0E8),
      fontSize: 16,
      bold: true,
      style: CardStyle.torn,
    ),
    TextCard(
      text: 'ANTHROPIC',
      paperColor: Color(0xFFE8E8E8),
      fontSize: 14,
      bold: true,
      style: CardStyle.textOnly,
    ),
    TextCard(
      text: 'AI & ETHICS',
      paperColor: Color(0xFFF0ECD8),
      fontSize: 14,
      bold: true,
      style: CardStyle.tornMore,
    ),
    TextCard(
      text: 'NO BORDERS',
      paperColor: Color(0xFFEAEAEA),
      fontSize: 13,
      bold: false,
      style: CardStyle.torn,
    ),
    TextCard(
      text: 'ANGEL INVESTOR',
      paperColor: Color(0xFFF5EFD6),
      fontSize: 12,
      bold: true,
      style: CardStyle.lined,
    ),
    TextCard(
      text: "i'm in love\nwith my future.",
      paperColor: Color(0xFFF2F2F2),
      fontSize: 12,
      bold: false,
      style: CardStyle.tornMore,
    ),
    TextCard(
      text: 'INVEST.\nGROW.\nREPEAT.',
      paperColor: Color(0xFFEDE8D0),
      fontSize: 14,
      bold: true,
      style: CardStyle.torn,
    ),
    TextCard(
      text: 'SHE WINS.',
      paperColor: Color(0xFFF5F0E8),
      fontSize: 15,
      bold: true,
      style: CardStyle.textOnly,
    ),
  ];

  /// Returns true if two rects overlap by more than 25% of the smaller card's area
  bool _overlaps(Rect a, Rect b) {
    if (!a.overlaps(b)) return false;
    final intersection = a.intersect(b);
    final smallerArea = min(a.width * a.height, b.width * b.height);
    return (intersection.width * intersection.height) > smallerArea * 0.25;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final rng = Random(56);

    const frameH = 24.0;
    const centerImgPath = 'imgs/87c88cb11e2f37df0fd2b4134692dbf2.jpg';
    const centerW = 220.0;
    const centerH = 220.0;

    final centerX = (screenW - centerW) / 2;
    final centerY = (screenH - centerH - frameH) / 2;

    final placedRects = <Rect>[];
    final positions = <Offset>[];
    final cardSizes = <Size>[];
    final angles = <double>[];
    final isText = <bool>[];
    final imgIndices = <int>[];

    // Reserve center area for the pinned image
    placedRects.add(Rect.fromLTWH(centerX, centerY, centerW, centerH + frameH));

    // Force 4 images to appear at the top of the screen
    final topForced = [
      Offset(
        rng.nextDouble() * (screenW * 0.25),
        8 + rng.nextDouble() * (screenH * 0.15),
      ),
      Offset(
        screenW * 0.25 + rng.nextDouble() * (screenW * 0.25),
        8 + rng.nextDouble() * (screenH * 0.15),
      ),
      Offset(
        screenW * 0.5 + rng.nextDouble() * (screenW * 0.25),
        8 + rng.nextDouble() * (screenH * 0.15),
      ),
      Offset(
        screenW * 0.75 + rng.nextDouble() * (screenW * 0.2),
        8 + rng.nextDouble() * (screenH * 0.15),
      ),
    ];

    final totalItems = images.length + textCards.length;
    final itemOrder = List.generate(totalItems, (i) => i)..shuffle(Random(33));

    int imgCount = 0;

    // Place image cards; text cards get placeholder positions for now
    for (int idx = 0; idx < itemOrder.length; idx++) {
      final itemIdx = itemOrder[idx];
      final isTxt = itemIdx >= images.length;

      double cw, ch;
      if (isTxt) {
        cw = 120.0 + rng.nextDouble() * 60;
        ch = 60.0 + rng.nextDouble() * 50;
      } else {
        cw = 100.0 + rng.nextDouble() * 80;
        ch = 100.0 + rng.nextDouble() * 80;
      }

      cardSizes.add(Size(cw, ch));
      angles.add((rng.nextDouble() - 0.5) * 0.45);
      isText.add(isTxt);

      if (isTxt) {
        positions.add(const Offset(0, 0));
        continue;
      }

      imgIndices.add(imgCount++);

      Offset? placed;
      if (idx < 4) {
        placed = topForced[idx];
        placedRects.add(Rect.fromLTWH(placed.dx, placed.dy, cw, ch));
      } else {
        for (int attempt = 0; attempt < 300; attempt++) {
          final x = 8 + rng.nextDouble() * (screenW - cw - 16);
          final y = 8 + rng.nextDouble() * (screenH - ch - 16);
          final rect = Rect.fromLTWH(x, y, cw, ch);
          if (!placedRects.any((r) => _overlaps(r, rect))) {
            placed = Offset(x, y);
            placedRects.add(rect);
            break;
          }
        }
      }

      positions.add(
        placed ??
            Offset(
              8 + rng.nextDouble() * (screenW - cw - 16),
              8 + rng.nextDouble() * (screenH - ch - 16),
            ),
      );
    }

    // Distribute text cards evenly across 8 zones (4 cols x 2 rows)
    const txtCols = 4;
    const txtRows = 2;
    final txtZoneW = screenW / txtCols;
    final txtZoneH = screenH / txtRows;
    final zoneOrder = List.generate(txtCols * txtRows, (i) => i)
      ..shuffle(Random(77));

    int textPlacedCount = 0;
    for (int idx = 0; idx < itemOrder.length; idx++) {
      if (!isText[idx]) continue;

      final size = cardSizes[idx];
      final cw = size.width;
      final ch = size.height;

      final zoneIdx = zoneOrder[textPlacedCount % zoneOrder.length];
      final zoneCol = zoneIdx % txtCols;
      final zoneRow = zoneIdx ~/ txtCols;
      final zoneLeft = zoneCol * txtZoneW;
      final zoneTop = zoneRow * txtZoneH;

      Offset? placed;
      for (int attempt = 0; attempt < 500; attempt++) {
        final x =
            zoneLeft +
            8 +
            rng.nextDouble() * (txtZoneW - cw - 16).clamp(0, double.infinity);
        final y =
            zoneTop +
            8 +
            rng.nextDouble() * (txtZoneH - ch - 16).clamp(0, double.infinity);
        final rect = Rect.fromLTWH(x, y, cw, ch);
        if (!placedRects.any((r) => _overlaps(r, rect))) {
          placed = Offset(x, y);
          placedRects.add(rect);
          break;
        }
      }

      positions[idx] =
          placed ??
          Offset(
            zoneLeft +
                8 +
                rng.nextDouble() *
                    (txtZoneW - cw - 16).clamp(0, double.infinity),
            zoneTop +
                8 +
                rng.nextDouble() *
                    (txtZoneH - ch - 16).clamp(0, double.infinity),
          );
      textPlacedCount++;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: ClipRect(
        child: SizedBox(
          width: screenW,
          height: screenH,
          child: Stack(
            children: [
              // Layer 1: Image cards
              ...List.generate(itemOrder.length, (idx) {
                if (isText[idx]) return const SizedBox.shrink();
                final pos = positions[idx];
                final size = cardSizes[idx];
                final angle = angles[idx];
                final iIdx =
                    imgIndices[idx < imgIndices.length
                        ? idx
                        : idx % imgIndices.length];
                return Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: Transform.rotate(
                    angle: angle,
                    child: _photoCard(
                      images[iIdx % images.length],
                      size.width,
                      size.height,
                      frameH,
                    ),
                  ),
                );
              }),

              // Layer 2: Center pinned image
              Positioned(
                left: centerX,
                top: centerY,
                child: _photoCard(centerImgPath, centerW, centerH, frameH),
              ),

              // Layer 3: Text cards (always rendered on top)
              ...() {
                int tCount = 0;
                return List.generate(itemOrder.length, (idx) {
                  if (!isText[idx]) return const SizedBox.shrink();
                  final pos = positions[idx];
                  final size = cardSizes[idx];
                  final angle = angles[idx];
                  final card = textCards[tCount % textCards.length];
                  tCount++;
                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: Transform.rotate(
                      angle: angle,
                      child: _tornPaperCard(card, size.width, size.height, idx),
                    ),
                  );
                });
              }(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a torn paper text card widget
  Widget _tornPaperCard(TextCard card, double w, double h, int seed) {
    if (card.style == CardStyle.textOnly) {
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Text(
            card.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: card.fontSize + 2,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 8),
                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 16),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: TornPaperPainter(
          color: card.paperColor,
          seed: seed,
          style: card.style,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              card.style == CardStyle.lined ? 36 : 12,
              16,
              12,
              12,
            ),
            child: Text(
              card.text,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFF1a1a1a),
                fontSize: card.fontSize,
                fontWeight: card.bold ? FontWeight.w800 : FontWeight.w400,
                letterSpacing: card.bold ? 1.5 : 0.5,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a polaroid-style photo card widget
  Widget _photoCard(String imagePath, double w, double h, double frameH) {
    return Container(
      width: w,
      height: h + frameH,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(3, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 4, frameH),
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}

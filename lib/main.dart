import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

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

enum CardStyle { torn, tornMore, lined, textOnly, stamp, handwritten }

class BoardCard {
  String? imageUrl;
  String? imageBase64;
  String? text;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  CardStyle style;
  int colorIndex;

  BoardCard({
    this.imageUrl,
    this.imageBase64,
    this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.style = CardStyle.torn,
    this.colorIndex = 0,
  });

  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    'imageBase64': imageBase64,
    'text': text,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'style': style.index,
    'colorIndex': colorIndex,
  };

  factory BoardCard.fromJson(Map<String, dynamic> json) => BoardCard(
    imageUrl: json['imageUrl'],
    imageBase64: json['imageBase64'],
    text: json['text'],
    x: json['x'],
    y: json['y'],
    width: json['width'],
    height: json['height'],
    rotation: json['rotation'] ?? 0,
    style: CardStyle.values[json['style'] ?? 0],
    colorIndex: json['colorIndex'] ?? 0,
  );
}

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
    if (style == CardStyle.textOnly ||
        style == CardStyle.stamp ||
        style == CardStyle.handwritten)
      return;

    final paint = Paint()..color = color;
    final path = Path();

    if (style == CardStyle.lined) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      final redPaint = Paint()
        ..color = const Color(0xFFFF9999).withOpacity(0.6)
        ..strokeWidth = 1.5;
      canvas.drawLine(const Offset(28, 0), Offset(28, size.height), redPaint);
      final linePaint = Paint()
        ..color = const Color(0xFF99BBDD).withOpacity(0.5)
        ..strokeWidth = 0.8;
      double lineY = 20;
      while (lineY < size.height) {
        canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), linePaint);
        lineY += 18;
      }
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

class VisionBoardPage extends StatefulWidget {
  const VisionBoardPage({super.key});

  @override
  State<VisionBoardPage> createState() => _VisionBoardPageState();
}

class _VisionBoardPageState extends State<VisionBoardPage> {
  List<BoardCard> cards = [];
  int? selectedIndex;
  bool isLoading = true;

  static const paperColors = [
    Color(0xFFF5F0E8),
    Color(0xFFE8E8E8),
    Color(0xFFF0ECD8),
    Color(0xFFEAEAEA),
    Color(0xFFF5EFD6),
    Color(0xFFF2F2F2),
    Color(0xFFEDE8D0),
    Color(0xFFFFE4E4),
    Color(0xFFE4F0FF),
  ];

  static const styleLabels = {
    CardStyle.torn: 'Torn',
    CardStyle.tornMore: 'Ripped',
    CardStyle.lined: 'Notebook',
    CardStyle.textOnly: 'Float',
    CardStyle.stamp: 'Stamp',
    CardStyle.handwritten: 'Script',
  };

  static const defaultImages = [
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
    'imgs/87c88cb11e2f37df0fd2b4134692dbf2.jpg',
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

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  Future<void> _loadBoard() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('board_cards');
    if (saved != null) {
      final List<dynamic> jsonList = jsonDecode(saved);
      setState(() {
        cards = jsonList.map((e) => BoardCard.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateDefaultBoard();
        setState(() => isLoading = false);
      });
    }
  }

  Future<void> _saveBoard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'board_cards',
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
  }

  void _generateDefaultBoard() {
    final rng = Random(56);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final placedRects = <Rect>[];
    final newCards = <BoardCard>[];

    const centerImgPath = 'imgs/87c88cb11e2f37df0fd2b4134692dbf2.jpg';
    const centerW = 220.0;
    const centerH = 220.0;
    final centerX = (screenW - centerW) / 2;
    final centerY = (screenH - centerH - 24) / 2;
    placedRects.add(Rect.fromLTWH(centerX, centerY, centerW, centerH + 24));

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

    int topCount = 0;
    for (final img in defaultImages) {
      if (img == centerImgPath) continue;
      final cw = 100.0 + rng.nextDouble() * 80;
      final ch = 100.0 + rng.nextDouble() * 80;
      Offset? placed;
      if (topCount < 4) {
        placed = topForced[topCount++];
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
      placed ??= Offset(
        8 + rng.nextDouble() * (screenW - cw - 16),
        8 + rng.nextDouble() * (screenH - ch - 16),
      );
      newCards.add(
        BoardCard(
          imageUrl: img,
          x: placed.dx,
          y: placed.dy,
          width: cw,
          height: ch,
          rotation: (rng.nextDouble() - 0.5) * 0.45,
        ),
      );
    }

    newCards.add(
      BoardCard(
        imageUrl: centerImgPath,
        x: centerX,
        y: centerY,
        width: centerW,
        height: centerH,
        rotation: 0,
      ),
    );

    final textItems = [
      ('DREAM BIG', CardStyle.torn, 0),
      ('ANTHROPIC', CardStyle.textOnly, 1),
      ('AI & ETHICS', CardStyle.tornMore, 2),
      ('NO BORDERS', CardStyle.torn, 3),
      ('ANGEL INVESTOR', CardStyle.lined, 4),
      ("i'm in love\nwith my future.", CardStyle.handwritten, 5),
      ('INVEST.\nGROW.\nREPEAT.', CardStyle.stamp, 6),
      ('SHE WINS.', CardStyle.textOnly, 0),
    ];

    const txtCols = 4;
    const txtRows = 2;
    final txtZoneW = screenW / txtCols;
    final txtZoneH = screenH / txtRows;
    final zoneOrder = List.generate(txtCols * txtRows, (i) => i)
      ..shuffle(Random(77));

    for (int i = 0; i < textItems.length; i++) {
      final (text, style, colorIdx) = textItems[i];
      final cw = 120.0 + rng.nextDouble() * 60;
      final ch = 60.0 + rng.nextDouble() * 50;
      final zoneIdx = zoneOrder[i % zoneOrder.length];
      final zoneLeft = (zoneIdx % txtCols) * txtZoneW;
      final zoneTop = (zoneIdx ~/ txtCols) * txtZoneH;
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
      placed ??= Offset(zoneLeft + 8, zoneTop + 8);
      newCards.add(
        BoardCard(
          text: text,
          x: placed.dx,
          y: placed.dy,
          width: cw,
          height: ch,
          rotation: (rng.nextDouble() - 0.5) * 0.45,
          style: style,
          colorIndex: colorIdx,
        ),
      );
    }

    setState(() => cards = newCards);
    _saveBoard();
  }

  bool _overlaps(Rect a, Rect b) {
    if (!a.overlaps(b)) return false;
    final intersection = a.intersect(b);
    final smallerArea = min(a.width * a.height, b.width * b.height);
    return (intersection.width * intersection.height) > smallerArea * 0.25;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    final base64Str = base64Encode(bytes);
    final rng = Random();
    setState(() {
      cards.add(
        BoardCard(
          imageBase64: base64Str,
          x: 80 + rng.nextDouble() * 100,
          y: 80 + rng.nextDouble() * 100,
          width: 150 + rng.nextDouble() * 60,
          height: 150 + rng.nextDouble() * 60,
          rotation: (rng.nextDouble() - 0.5) * 0.3,
        ),
      );
    });
    _saveBoard();
  }

  void _showTextDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final card = isEdit ? cards[editIndex] : null;
    final controller = TextEditingController(text: card?.text ?? '');
    CardStyle selectedStyle = card?.style ?? CardStyle.torn;
    int selectedColor = card?.colorIndex ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1a1a1a),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Text Card' : 'Add Text Card',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 4,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Enter your text...',
                              hintStyle: TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Style',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: CardStyle.values.map((s) {
                              final isSel = selectedStyle == s;
                              return GestureDetector(
                                onTap: () =>
                                    setDialogState(() => selectedStyle = s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? Colors.white
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    styleLabels[s]!,
                                    style: TextStyle(
                                      color: isSel
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Paper Color',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: List.generate(
                              paperColors.length,
                              (i) => GestureDetector(
                                onTap: () =>
                                    setDialogState(() => selectedColor = i),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: paperColors[i],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == i
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 180,
                          height: 180,
                          color: const Color(0xFF0a0a0a),
                          child: Center(
                            child: _buildPreviewCard(
                              text: controller.text.isEmpty
                                  ? 'Your text here'
                                  : controller.text,
                              style: selectedStyle,
                              colorIndex: selectedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          setState(() {
                            if (isEdit) {
                              cards[editIndex].text = controller.text;
                              cards[editIndex].style = selectedStyle;
                              cards[editIndex].colorIndex = selectedColor;
                            } else {
                              final rng = Random();
                              cards.add(
                                BoardCard(
                                  text: controller.text,
                                  x: 100,
                                  y: 100,
                                  width: 160,
                                  height: 90,
                                  rotation: (rng.nextDouble() - 0.5) * 0.3,
                                  style: selectedStyle,
                                  colorIndex: selectedColor,
                                ),
                              );
                            }
                          });
                          _saveBoard();
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        isEdit ? 'Save' : 'Add',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard({
    required String text,
    required CardStyle style,
    required int colorIndex,
  }) {
    final color = paperColors[colorIndex % paperColors.length];
    if (style == CardStyle.textOnly)
      return Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.playfairDisplay(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 8),
          ],
        ),
      );
    if (style == CardStyle.stamp)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      );
    if (style == CardStyle.handwritten)
      return Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.dancingScript(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      );
    return CustomPaint(
      painter: TornPaperPainter(
        color: color,
        seed: text.hashCode,
        style: style,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          style == CardStyle.lined ? 36 : 12,
          16,
          12,
          12,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF1a1a1a),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  void _deleteCard(int index) {
    setState(() {
      cards.removeAt(index);
      selectedIndex = null;
    });
    _saveBoard();
  }

  void _bringForward(int index) {
    if (index < cards.length - 1) {
      setState(() {
        final c = cards.removeAt(index);
        cards.insert(index + 1, c);
        selectedIndex = index + 1;
      });
      _saveBoard();
    }
  }

  void _sendBackward(int index) {
    if (index > 0) {
      setState(() {
        final c = cards.removeAt(index);
        cards.insert(index - 1, c);
        selectedIndex = index - 1;
      });
      _saveBoard();
    }
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Reset Board', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will reset the board to its original state. Are you sure?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('board_cards');
              setState(() {
                cards = [];
                selectedIndex = null;
              });
              _generateDefaultBoard();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Build control handle button
  Widget _handle({
    required IconData icon,
    required Color bg,
    required Color iconColor,
    VoidCallback? onTap,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragEndCallback? onPanEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: GestureDetector(
        onTap: () => setState(() => selectedIndex = null),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Cards
            ...List.generate(cards.length, (index) {
              final card = cards[index];
              return Positioned(
                left: card.x,
                top: card.y,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(
                    () => selectedIndex = selectedIndex == index ? null : index,
                  ),
                  onDoubleTap: () {
                    if (card.text != null) _showTextDialog(editIndex: index);
                  },
                  onPanUpdate: (d) {
                    setState(() {
                      card.x += d.delta.dx;
                      card.y += d.delta.dy;
                    });
                  },
                  onPanEnd: (_) => _saveBoard(),
                  child: Transform.rotate(
                    angle: card.rotation,
                    child: card.imageUrl != null || card.imageBase64 != null
                        ? _buildPhotoCard(card)
                        : _buildTextCard(card),
                  ),
                ),
              );
            }),

            // Control overlay - completely separate from cards
            if (selectedIndex != null && selectedIndex! < cards.length)
              ..._buildControls(cards[selectedIndex!], selectedIndex!),

            // Toolbar
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _toolbarButton(Icons.upload_file, 'Upload Image', _pickImage),
                  const SizedBox(width: 12),
                  _toolbarButton(
                    Icons.text_fields,
                    'Add Text',
                    () => _showTextDialog(),
                  ),
                  const SizedBox(width: 12),
                  _toolbarButton(Icons.save, 'Save', () async {
                    await _saveBoard();
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Board saved! ✨'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xFF1a1a1a),
                        ),
                      );
                  }),
                  const SizedBox(width: 12),
                  _toolbarButton(Icons.refresh, 'Reset', _confirmReset),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build control handles as overlay - completely independent from card widgets
  List<Widget> _buildControls(BoardCard card, int index) {
    final left = card.x;
    final top = card.y;
    final right = card.x + card.width;
    final bottom = card.y + card.height + 24;

    return [
      // Delete - top right
      Positioned(
        left: right - 14,
        top: top - 14,
        child: _handle(
          icon: Icons.close,
          bg: Colors.red,
          iconColor: Colors.white,
          onTap: () => _deleteCard(index),
        ),
      ),

      // Send backward - top left
      Positioned(
        left: left - 14,
        top: top - 14,
        child: _handle(
          icon: Icons.arrow_downward,
          bg: Colors.white,
          iconColor: Colors.black,
          onTap: () => _sendBackward(index),
        ),
      ),

      // Bring forward - top left + offset
      Positioned(
        left: left + 18,
        top: top - 14,
        child: _handle(
          icon: Icons.arrow_upward,
          bg: Colors.white,
          iconColor: Colors.black,
          onTap: () => _bringForward(index),
        ),
      ),

      // Resize - bottom right
      Positioned(
        left: right - 14,
        top: bottom - 14,
        child: _handle(
          icon: Icons.open_in_full,
          bg: Colors.white,
          iconColor: Colors.black,
          onPanUpdate: (d) => setState(() {
            card.width = (card.width + d.delta.dx).clamp(60, 400);
            card.height = (card.height + d.delta.dy).clamp(40, 400);
          }),
          onPanEnd: (_) => _saveBoard(),
        ),
      ),

      // Rotate - bottom left
      Positioned(
        left: left - 14,
        top: bottom - 14,
        child: _handle(
          icon: Icons.rotate_right,
          bg: Colors.white,
          iconColor: Colors.black,
          onPanUpdate: (d) =>
              setState(() => card.rotation += d.delta.dx * 0.01),
          onPanEnd: (_) => _saveBoard(),
        ),
      ),
    ];
  }

  Widget _buildPhotoCard(BoardCard card) {
    return Container(
      width: card.width,
      height: card.height + 24,
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
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        child: card.imageBase64 != null
            ? Image.memory(
                base64Decode(card.imageBase64!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            : Image.asset(
                card.imageUrl!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      ),
    );
  }

  Widget _buildTextCard(BoardCard card) {
    final color = paperColors[card.colorIndex % paperColors.length];

    if (card.style == CardStyle.textOnly) {
      return SizedBox(
        width: card.width,
        height: card.height,
        child: Center(
          child: Text(
            card.text!,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 8),
              ],
            ),
          ),
        ),
      );
    }
    if (card.style == CardStyle.stamp) {
      return Container(
        width: card.width,
        height: card.height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          card.text!,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      );
    }
    if (card.style == CardStyle.handwritten) {
      return Container(
        width: card.width,
        height: card.height,
        alignment: Alignment.center,
        child: Text(
          card.text!,
          textAlign: TextAlign.center,
          style: GoogleFonts.dancingScript(
            color: Colors.white.withOpacity(0.9),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 6),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: card.width,
      height: card.height,
      child: CustomPaint(
        painter: TornPaperPainter(
          color: color,
          seed: card.text.hashCode,
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
              card.text!,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFF1a1a1a),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

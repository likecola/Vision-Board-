import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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

enum CardStyle {
  torn,
  tornMore,
  lined,
  textOnly,
  stamp,
  handwritten,
  neon,
  hologram,
  bubble,
  outline,
  retro,
  glitch,
  chrome,
  rainbow,
}

enum BgType { solid, gradient, dots, lines, grid, crosshatch, image }

class BoardBackground {
  BgType type;
  int color1, color2, color3;
  bool useColor3;
  double patternSize;
  String? imageBase64;
  String? imageAsset;

  BoardBackground({
    this.type = BgType.solid,
    this.color1 = 0xFF0a0a0a,
    this.color2 = 0xFF1a1a2e,
    this.color3 = 0xFF16213e,
    this.useColor3 = false,
    this.patternSize = 20.0,
    this.imageBase64,
    this.imageAsset,
  });

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'color1': color1,
    'color2': color2,
    'color3': color3,
    'useColor3': useColor3,
    'patternSize': patternSize,
    'imageBase64': imageBase64,
    'imageAsset': imageAsset,
  };

  factory BoardBackground.fromJson(Map<String, dynamic> json) =>
      BoardBackground(
        type: BgType.values[json['type'] ?? 0],
        color1: json['color1'] ?? 0xFF0a0a0a,
        color2: json['color2'] ?? 0xFF1a1a2e,
        color3: json['color3'] ?? 0xFF16213e,
        useColor3: json['useColor3'] ?? false,
        patternSize: json['patternSize'] ?? 20.0,
        imageBase64: json['imageBase64'],
        imageAsset: json['imageAsset'],
      );
}

class BoardCard {
  String? imageUrl, imageBase64, text;
  double xRatio, yRatio, widthRatio, heightRatio, rotation;
  CardStyle style;
  int paperColor, textColor;

  BoardCard({
    this.imageUrl,
    this.imageBase64,
    this.text,
    required this.xRatio,
    required this.yRatio,
    required this.widthRatio,
    required this.heightRatio,
    this.rotation = 0,
    this.style = CardStyle.torn,
    this.paperColor = 0xFFF5F0E8,
    this.textColor = 0xFF1a1a1a,
  });

  double x(double w) => xRatio * w;
  double y(double h) => yRatio * h;
  double width(double w) => widthRatio * w;
  double height(double w) => heightRatio * w;

  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    'imageBase64': imageBase64,
    'text': text,
    'xRatio': xRatio,
    'yRatio': yRatio,
    'widthRatio': widthRatio,
    'heightRatio': heightRatio,
    'rotation': rotation,
    'style': style.index,
    'paperColor': paperColor,
    'textColor': textColor,
  };

  factory BoardCard.fromJson(Map<String, dynamic> json) {
    final hasRatio = json.containsKey('xRatio');
    final si = json['style'] ?? 0;
    return BoardCard(
      imageUrl: json['imageUrl'],
      imageBase64: json['imageBase64'],
      text: json['text'],
      xRatio: hasRatio ? json['xRatio'] : 0.1,
      yRatio: hasRatio ? json['yRatio'] : 0.1,
      widthRatio: hasRatio ? json['widthRatio'] : 0.12,
      heightRatio: hasRatio ? json['heightRatio'] : 0.12,
      rotation: json['rotation'] ?? 0,
      style: si < CardStyle.values.length
          ? CardStyle.values[si]
          : CardStyle.torn,
      paperColor: json['paperColor'] ?? 0xFFF5F0E8,
      textColor: json['textColor'] ?? 0xFF1a1a1a,
    );
  }
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
    final skip = [
      CardStyle.textOnly,
      CardStyle.stamp,
      CardStyle.handwritten,
      CardStyle.neon,
      CardStyle.hologram,
      CardStyle.bubble,
      CardStyle.outline,
      CardStyle.retro,
      CardStyle.glitch,
      CardStyle.chrome,
      CardStyle.rainbow,
    ];
    if (skip.contains(style)) return;
    final paint = Paint()..color = color;
    if (style == CardStyle.lined) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      canvas.drawLine(
        const Offset(28, 0),
        Offset(28, size.height),
        Paint()
          ..color = const Color(0xFFFF9999).withOpacity(0.6)
          ..strokeWidth = 1.5,
      );
      final lp = Paint()
        ..color = const Color(0xFF99BBDD).withOpacity(0.5)
        ..strokeWidth = 0.8;
      double ly = 20;
      while (ly < size.height) {
        canvas.drawLine(Offset(0, ly), Offset(size.width, ly), lp);
        ly += 18;
      }
      final tp = Paint()..color = const Color(0xFF0a0a0a);
      final top = Path();
      top.moveTo(0, 0);
      double x = 0;
      while (x < size.width) {
        x += 5 + rng.nextDouble() * 7;
        top.lineTo(x.clamp(0, size.width), rng.nextDouble() * 10);
      }
      top.lineTo(size.width, 0);
      top.close();
      canvas.drawPath(top, tp);
      final bot = Path();
      bot.moveTo(0, size.height);
      x = 0;
      while (x < size.width) {
        x += 5 + rng.nextDouble() * 7;
        bot.lineTo(x.clamp(0, size.width), size.height - rng.nextDouble() * 10);
      }
      bot.lineTo(size.width, size.height);
      bot.close();
      canvas.drawPath(bot, tp);
      return;
    }
    final r = style == CardStyle.tornMore ? 0.25 : 0.15;
    final path = Path();
    path.moveTo(0, size.height * r);
    double xp = 0;
    while (xp < size.width) {
      xp += 4 + rng.nextDouble() * (style == CardStyle.tornMore ? 6 : 8);
      path.lineTo(
        xp.clamp(0, size.width),
        size.height * 0.02 + rng.nextDouble() * size.height * r,
      );
    }
    path.lineTo(size.width, size.height * (1 - r));
    xp = size.width;
    while (xp > 0) {
      xp -= 4 + rng.nextDouble() * (style == CardStyle.tornMore ? 6 : 8);
      path.lineTo(
        xp.clamp(0, size.width),
        size.height * (1 - r * 0.3) + rng.nextDouble() * size.height * r,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class BackgroundPainter extends CustomPainter {
  final BoardBackground bg;
  BackgroundPainter(this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    final c1 = Color(bg.color1);
    final c2 = Color(bg.color2);
    final c3 = Color(bg.color3);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (bg.type == BgType.solid || bg.type == BgType.image) {
      canvas.drawRect(rect, Paint()..color = c1);
      return;
    }
    if (bg.type == BgType.gradient) {
      final colors = bg.useColor3 ? [c1, c2, c3] : [c1, c2];
      final stops = bg.useColor3 ? [0.0, 0.5, 1.0] : [0.0, 1.0];
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: colors,
            stops: stops,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
      );
      return;
    }
    canvas.drawRect(rect, Paint()..color = c1);
    final pp = Paint()
      ..color = c2
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final sp = bg.patternSize;
    if (bg.type == BgType.dots) {
      pp.style = PaintingStyle.fill;
      for (double x = sp; x < size.width; x += sp)
        for (double y = sp; y < size.height; y += sp)
          canvas.drawCircle(Offset(x, y), 1.5, pp);
      return;
    }
    if (bg.type == BgType.lines) {
      for (double y = 0; y < size.height; y += sp)
        canvas.drawLine(Offset(0, y), Offset(size.width, y), pp);
      return;
    }
    if (bg.type == BgType.grid) {
      for (double x = 0; x < size.width; x += sp)
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), pp);
      for (double y = 0; y < size.height; y += sp)
        canvas.drawLine(Offset(0, y), Offset(size.width, y), pp);
      return;
    }
    if (bg.type == BgType.crosshatch) {
      for (double i = -size.height; i < size.width + size.height; i += sp) {
        canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), pp);
        canvas.drawLine(Offset(i + size.height, 0), Offset(i, size.height), pp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter old) =>
      old.bg.type != bg.type ||
      old.bg.color1 != bg.color1 ||
      old.bg.color2 != bg.color2 ||
      old.bg.color3 != bg.color3 ||
      old.bg.useColor3 != bg.useColor3 ||
      old.bg.patternSize != bg.patternSize;
}

class VisionBoardPage extends StatefulWidget {
  const VisionBoardPage({super.key});
  @override
  State<VisionBoardPage> createState() => _VisionBoardPageState();
}

class _VisionBoardPageState extends State<VisionBoardPage>
    with TickerProviderStateMixin {
  List<BoardCard> cards = [];
  BoardBackground background = BoardBackground();
  int? selectedIndex;
  bool isLoading = true;
  bool _animStarted = false;
  bool _isExporting = false;
  String _currentMood = 'manifestation';

  final GlobalKey _boardKey = GlobalKey();
  late AnimationController _introController;
  late AnimationController _floatController;
  late AnimationController _neonController;
  final List<double> _floatOffsets = [];
  static const _stickerCurve = _StickerCurve();

  // ★ 무드별 플로팅 진폭
  double get _floatAmplitude {
    switch (_currentMood) {
      case 'manifestation':
        return 6.0;
      case 'soft_life':
        return 2.5;
      case 'that_girl':
        return 1.0;
      case 'cyber_dream':
        return 8.0;
      case 'wanderlust':
        return 5.0;
      default:
        return 4.0;
    }
  }

  // ★ 무드별 플로팅 속도 (초)
  double get _floatSpeedSeconds {
    switch (_currentMood) {
      case 'manifestation':
        return 2.5;
      case 'soft_life':
        return 5.0;
      case 'that_girl':
        return 4.0;
      case 'cyber_dream':
        return 1.2;
      case 'wanderlust':
        return 3.5;
      default:
        return 3.0;
    }
  }

  // ★ 무드별 네온 깜빡임 강도
  double get _neonIntensityBase {
    switch (_currentMood) {
      case 'manifestation':
        return 0.5;
      case 'cyber_dream':
        return 0.15;
      default:
        return 0.7;
    }
  }

  static const styleLabels = {
    CardStyle.torn: 'Torn',
    CardStyle.tornMore: 'Ripped',
    CardStyle.lined: 'Notebook',
    CardStyle.textOnly: 'Float',
    CardStyle.stamp: 'Stamp',
    CardStyle.handwritten: 'Script',
    CardStyle.neon: '⚡ Neon',
    CardStyle.hologram: '🌈 Holo',
    CardStyle.bubble: '🫧 Bubble',
    CardStyle.outline: '⬜ Outline',
    CardStyle.retro: '🎮 Retro',
    CardStyle.glitch: '👾 Glitch',
    CardStyle.chrome: '🪞 Chrome',
    CardStyle.rainbow: '🌈 Rainbow',
  };

  static const bgTypeLabels = {
    BgType.solid: 'Solid',
    BgType.gradient: 'Gradient',
    BgType.dots: 'Dots',
    BgType.lines: 'Lines',
    BgType.grid: 'Grid',
    BgType.crosshatch: 'Cross',
    BgType.image: 'Image',
  };

  static const presetPaperColors = [
    Color(0xFFF5F0E8),
    Color(0xFFE8E8E8),
    Color(0xFFF0ECD8),
    Color(0xFFEAEAEA),
    Color(0xFFF5EFD6),
    Color(0xFFF2F2F2),
    Color(0xFFEDE8D0),
    Color(0xFFFFE4E4),
    Color(0xFFE4F0FF),
    Color(0xFFE8F5E8),
    Color(0xFFFFF3CD),
    Color(0xFFEDE0FF),
  ];

  static const presetTextColors = [
    Color(0xFF1a1a1a),
    Color(0xFFFFFFFF),
    Color(0xFF8B0000),
    Color(0xFF1B3A6B),
    Color(0xFF2D5A27),
    Color(0xFF4A0E5C),
    Color(0xFFB8860B),
    Color(0xFF8B4513),
    Color(0xFF006666),
    Color(0xFF8B008B),
  ];

  static final bgPresets = [
    {
      'name': 'Black',
      'bg': BoardBackground(type: BgType.solid, color1: 0xFF0a0a0a),
    },
    {
      'name': 'Dark Blue',
      'bg': BoardBackground(
        type: BgType.gradient,
        color1: 0xFF0a0a1a,
        color2: 0xFF1a1a3e,
      ),
    },
    {
      'name': 'Midnight',
      'bg': BoardBackground(
        type: BgType.gradient,
        color1: 0xFF0d0d0d,
        color2: 0xFF1a0a2e,
        color3: 0xFF0a1a2e,
        useColor3: true,
      ),
    },
    {
      'name': 'Warm Dark',
      'bg': BoardBackground(
        type: BgType.gradient,
        color1: 0xFF1a0a00,
        color2: 0xFF2e1a0a,
      ),
    },
    {
      'name': 'Dots',
      'bg': BoardBackground(
        type: BgType.dots,
        color1: 0xFF0a0a0a,
        color2: 0xFF333333,
        patternSize: 24,
      ),
    },
    {
      'name': 'Grid',
      'bg': BoardBackground(
        type: BgType.grid,
        color1: 0xFF0a0a0a,
        color2: 0xFF1e1e1e,
        patternSize: 30,
      ),
    },
    {
      'name': 'Lines',
      'bg': BoardBackground(
        type: BgType.lines,
        color1: 0xFF0a0a0a,
        color2: 0xFF1e1e1e,
        patternSize: 28,
      ),
    },
    {
      'name': 'Cross',
      'bg': BoardBackground(
        type: BgType.crosshatch,
        color1: 0xFF0a0a0a,
        color2: 0xFF1a1a1a,
        patternSize: 20,
      ),
    },
    {
      'name': 'Forest',
      'bg': BoardBackground(
        type: BgType.gradient,
        color1: 0xFF0a1a0a,
        color2: 0xFF1a2e1a,
      ),
    },
    {
      'name': 'Rose',
      'bg': BoardBackground(
        type: BgType.gradient,
        color1: 0xFF1a0a0f,
        color2: 0xFF2e0a1a,
      ),
    },
    {
      'name': 'White',
      'bg': BoardBackground(type: BgType.solid, color1: 0xFFF5F0E8),
    },
    {
      'name': 'Cream',
      'bg': BoardBackground(
        type: BgType.dots,
        color1: 0xFFF5F0E8,
        color2: 0xFFDDD8CC,
        patternSize: 20,
      ),
    },
  ];

  static const defaultImages = [
    'imgs/Manifestation/0058235e3ebb2729faf21be0403e05df.jpg',
    'imgs/Manifestation/015429bcd1aab1991f004d9ee9fdd3aa.jpg',
    'imgs/Manifestation/1500e1282e7a2875d7066cf3647a9fba.jpg',
    'imgs/Manifestation/2555133c526c260b0468435a6e015014.jpg',
    'imgs/Manifestation/267c84483e854b8c522368366af931d5.jpg',
    'imgs/Manifestation/2bd78ea72b681460f5e66bd58508053a.jpg',
    'imgs/Manifestation/2d39cdb4711cd7d59bd7e2cd6f47a284.jpg',
    'imgs/Manifestation/2e0337bf91f32a6ef1ea696829059b95.jpg',
    'imgs/Manifestation/2fdbfddd084b6fa839c49678121e1373.jpg',
    'imgs/Manifestation/3f9dc2e8a65259a47732248c1c9f7e0f.jpg',
    'imgs/Manifestation/470ff04d04eea0ae117783d12deb3431.jpg',
    'imgs/Manifestation/4f459f0c682cbaf55f08e91a55b381d1.jpg',
    'imgs/Manifestation/56e368e13a4f79c1196a321d0f7eaa9e.jpg',
    'imgs/Manifestation/5ae0ab29aa6572d938dcd58ad06d3518.jpg',
    'imgs/Manifestation/5b13d82833aa572e10b94722afe025cd.jpg',
    'imgs/Manifestation/5b4a5382b47fab34d65dd1eb5f8f3660.jpg',
    'imgs/Manifestation/62722e12b7fd9a21fa15843666d06c35.jpg',
    'imgs/Manifestation/64f589d7e4e6f1288907fef9575332f5.jpg',
    'imgs/Manifestation/820fa7d61221505a529323b7d54e0ad4.jpg',
    'imgs/Manifestation/8570b14f818387643170e52719063036.jpg',
    'imgs/Manifestation/87c88cb11e2f37df0fd2b4134692dbf2.jpg',
    'imgs/Manifestation/89fd9414c37a076060865cc59231fb97.jpg',
    'imgs/Manifestation/8e90048fbaad09eae2a4d2726c3b693d.jpg',
    'imgs/Manifestation/90281e2309ec2ec0e4a8271c06f326f6.jpg',
    'imgs/Manifestation/917ff1305c11db37c219693aad437d52.jpg',
    'imgs/Manifestation/984d44fa26519c56841468899e30ee1b.jpg',
    'imgs/Manifestation/9e73a6ad113b3189f3ccd34bbcb8edcd.jpg',
    'imgs/Manifestation/b4e4a383ebd0d41c7bb48603132a396a.jpg',
    'imgs/Manifestation/daf20a82e77d072196224d0ea525d13b.jpg',
    'imgs/Manifestation/dce74a4b5684af80207214f5343d963d.jpg',
    'imgs/Manifestation/download.png',
    'imgs/Manifestation/f409f422e30e12fd1b73b2c68a78160e.jpg',
    'imgs/Manifestation/f6fbfd0d0714a01e3504d751dc1c6b29.jpg',
    'imgs/Manifestation/fd67b28749505d645c4c7eb279124f9e.jpg',
    'imgs/Manifestation/fd88e0b4103cb45944cc27d6a48207b8.jpg',
  ];

  static const moodImages = {
    'soft_life': [
      'imgs/soft_life/397296e8caa6791e949d9764344c3cb7.jpg',
      'imgs/soft_life/3db58c55748436c2c919260c2918d884.jpg',
      'imgs/soft_life/50a7eab35d893750c7cdfc7342e58149.jpg',
      'imgs/soft_life/5f269333b771c1a6586b9e72a410c5da.jpg',
      'imgs/soft_life/7d124fb39c37b2b73ab8e9e20d33d3ea.jpg',
      'imgs/soft_life/9054c9d1c125fe8d48b457694d325003.jpg',
      'imgs/soft_life/94ed7c46bdb0c65a154c4524ca849fc9.jpg',
      'imgs/soft_life/9e34c0a3a95ea2af7718162eaf57f17f.jpg',
      'imgs/soft_life/9e8abfb9a82a4909f5dd09829ed3d027.jpg',
      'imgs/soft_life/af40025ac695bb3be7b130203b84c07e.jpg',
      'imgs/soft_life/bb984b2d629044af6dad472cba02fcce.jpg',
      'imgs/soft_life/ce86653af823fdc0abeaabf05c4d2dad.jpg',
      'imgs/soft_life/f76564f53cdf3b405db3844c4ecd26c6.jpg',
    ],
    'that_girl': [
      'imgs/That_Girl/07d880005cff37003ed0bf38c0b1255e.jpg',
      'imgs/That_Girl/08adcc76ccc4169152c1f8351540a6bc.jpg',
      'imgs/That_Girl/17dada98387c1bfad6f8a9ea5cf85353.jpg',
      'imgs/That_Girl/2af06e82c4611eb9456b9a61d61a5517.jpg',
      'imgs/That_Girl/332a5a4c8603386a7d878c341559bf93.jpg',
      'imgs/That_Girl/47b3610e80215ee88ee9f02ec5dc01dd.jpg',
      'imgs/That_Girl/844f4c055d9aebae18cf054574bb7442.jpg',
      'imgs/That_Girl/94df95c735206faace48660d8eda3ea3.jpg',
      'imgs/That_Girl/a597ca0becf1821e0434b5fe72582267.jpg',
      'imgs/That_Girl/b8a8dc19bedd05b6fba0d2639b794df0.jpg',
      'imgs/That_Girl/c1486e95f3d4c09cfcc6b8dff252c240.jpg',
      'imgs/That_Girl/d29158c2bb8c2a5d89b885eef79092f1.jpg',
      'imgs/That_Girl/d8a9b7aaa459b45b48cd96ebe1815485.jpg',
      'imgs/That_Girl/da3806c8af586dbc99579f76e5ac1ece.jpg',
      'imgs/That_Girl/e0eca264f028a3a3620c5936a02e6879.jpg',
    ],
    'cyber_dream': [
      'imgs/Cyber_Dream/01f1b09eed0368b4f2b6cf8f9b425a54.jpg',
      'imgs/Cyber_Dream/42cc480f18c4085f97b9ce9230e43a46.jpg',
      'imgs/Cyber_Dream/450b9a9d479faa2fef4afeefb4c23ddf.jpg',
      'imgs/Cyber_Dream/5cba281f44c039c4d3e575ffc5624f7d.jpg',
      'imgs/Cyber_Dream/65c4f1863636a89ede8db51693b8cf2b.jpg',
      'imgs/Cyber_Dream/690dd4a8220f4ce2c27bc752fea4d782.jpg',
      'imgs/Cyber_Dream/73c97c83550d909687823d5c10b529b1.jpg',
      'imgs/Cyber_Dream/ac35ac79a27f5fddcd169c8ceb1b0ed2.jpg',
      'imgs/Cyber_Dream/b16374c3be0ae2906ffcf6f9eeb6ab2f.jpg',
      'imgs/Cyber_Dream/b6a4be8d7ffd61cdcfde4db2b97baa83.jpg',
      'imgs/Cyber_Dream/bf35e957ac979b55a8232418d0aeae57.jpg',
      'imgs/Cyber_Dream/c7cd4dde24c8fcfeeddc73899a45c4b0.jpg',
      'imgs/Cyber_Dream/ce6e32a1b0e199432945a9f4422feba7.jpg',
      'imgs/Cyber_Dream/dd17f7fed0880776d6f363f47a1b4ace.jpg',
      'imgs/Cyber_Dream/ddcc9ee3f0f91d472d99f71c0d8e511a.jpg',
      'imgs/Cyber_Dream/df0d0e247072e7e3847a417f2a716620.jpg',
      'imgs/Cyber_Dream/ece2699cdefc930e16b2f8325cc50fd0.jpg',
      'imgs/Cyber_Dream/f971c54106397d8c4ce3b7ca1a63ec8d.jpg',
    ],
    'wanderlust': [
      'imgs/wanderlust/09b075dd2be0bc09f4d3e62e47119233.jpg',
      'imgs/wanderlust/0c8c143a5177db233c417e17db188e0f.jpg',
      'imgs/wanderlust/18ccf04f7a0288b95fe471a4e36fe487.jpg',
      'imgs/wanderlust/1f31141549feb9c06c69e53ccad09cc1.jpg',
      'imgs/wanderlust/218b94b7471b0383449df2bdacb14ef2.jpg',
      'imgs/wanderlust/231a533d5a1c7d764d00709fd7fb1085.jpg',
      'imgs/wanderlust/29d3ab642d1b1ec2437e9ef2880bdbc5.jpg',
      'imgs/wanderlust/5c72a14678c6457d25e4751d5a37ed0e.jpg',
      'imgs/wanderlust/665d270d9f1e5096af29bd22bb0e1530.jpg',
      'imgs/wanderlust/71d7e0511be74210fec8bb6dfb96a7ad.jpg',
      'imgs/wanderlust/75d52d7ba742ea0899cd890417830ebb.jpg',
      'imgs/wanderlust/a186582b3c2111fea6bc003779d1d2e9.jpg',
      'imgs/wanderlust/a69971e14d829ddc4fadb02b10eede7d.jpg',
      'imgs/wanderlust/b01813e0e62bb7ed80ab2e8599614f4d.jpg',
      'imgs/wanderlust/b085ce9ceddb4177eb931d188c720575.jpg',
      'imgs/wanderlust/c281894392e9fd1d065de136c1ea59d7.jpg',
      'imgs/wanderlust/cd0791521392fafe5abbdfb458757a2f.jpg',
    ],
  };

  static const moodTextSets = {
    'manifestation': [
      ('BOSS ERA', CardStyle.neon, 0xFFF5F0E8, 0xFFFF6EC7),
      ('MAKE IT HAPPEN', CardStyle.hologram, 0xFFF5F0E8, 0xFFFFFFFF),
      ('MAIN CHARACTER', CardStyle.bubble, 0xFFF0ECD8, 0xFFFFFFFF),
      ('BIG MOVES ONLY', CardStyle.glitch, 0xFFEAEAEA, 0xFFFFFFFF),
      ('LEVEL UP', CardStyle.retro, 0xFFF5EFD6, 0xFFFFD700),
      (
        "i'm in love\nwith my future.",
        CardStyle.handwritten,
        0xFFF5F0E8,
        0xFFFFFFFF,
      ),
      ('SHE WINS.', CardStyle.chrome, 0xFFEDE8D0, 0xFFFFFFFF),
      ('DREAM BIG', CardStyle.rainbow, 0xFFF5F0E8, 0xFFFFFFFF),
    ],
    'soft_life': [
      (
        'slow down,\nit\'s okay.',
        CardStyle.handwritten,
        0xFFF7EFE5,
        0xFF3D2314,
      ),
      ('rest is\nproductive.', CardStyle.torn, 0xFFF0E4D0, 0xFF3D2314),
      ('joy is enough.', CardStyle.lined, 0xFFF7EFE5, 0xFF3D2314),
      ('nourish &\nflourish.', CardStyle.handwritten, 0xFFEDE0D0, 0xFF3D2314),
      ('SELF CARE\nFIRST', CardStyle.stamp, 0xFFD4956A, 0xFFF7EFE5),
      (
        'peace over\neverything.',
        CardStyle.handwritten,
        0xFFF7EFE5,
        0xFF3D2314,
      ),
      ('HEALING ERA', CardStyle.textOnly, 0xFFF7EFE5, 0xFFD4956A),
      ('choose gentle.', CardStyle.tornMore, 0xFFEDE0D0, 0xFF3D2314),
    ],
    'that_girl': [
      ('05:30', CardStyle.stamp, 0xFF080808, 0xFFC8A97E),
      ('DISCIPLINE', CardStyle.outline, 0xFF080808, 0xFFFFFFFF),
      ('HUSTLE', CardStyle.chrome, 0xFF080808, 0xFFFFFFFF),
      ('DEBT FREE', CardStyle.textOnly, 0xFF080808, 0xFFFFFFFF),
      ('I AM THAT GIRL', CardStyle.stamp, 0xFF080808, 0xFFC8A97E),
      ('FINANCIALLY\nFREE', CardStyle.outline, 0xFF080808, 0xFFFFFFFF),
      ('show up\nevery day.', CardStyle.torn, 0xFF222222, 0xFFFFFFFF),
      (
        'discipline\nis self love.',
        CardStyle.handwritten,
        0xFF111111,
        0xFFFFFFFF,
      ),
    ],
    'cyber_dream': [
      ('NO ONE CAN\nSAVE YOU\nBUT ME', CardStyle.neon, 0xFF0d0520, 0xFFFF2D9E),
      ('ENTER\nTHE VOID', CardStyle.glitch, 0xFF0d0520, 0xFF00F5FF),
      ('GLITCH\nTHE SYSTEM', CardStyle.bubble, 0xFF0d0520, 0xFFE8B4FF),
      ('UNPLUG.\nRESET.', CardStyle.neon, 0xFF0d0520, 0xFFFF2D9E),
      ('BEYOND\nLIMITS', CardStyle.glitch, 0xFF0d0520, 0xFF00F5FF),
      ('DREAM IN\nPIXELS', CardStyle.hologram, 0xFF0d0520, 0xFFE8B4FF),
      ('LIVE IN NEON', CardStyle.neon, 0xFF0d0520, 0xFFFF2D9E),
      ('CTRL+ALT\n+MANIFEST', CardStyle.outline, 0xFF0d0520, 0xFF00F5FF),
    ],
    'wanderlust': [
      ('to travel\nis to live.', CardStyle.retro, 0xFF0E2A3A, 0xFF6BAED6),
      ('FLOW', CardStyle.torn, 0xFF1A3D5C, 0xFFE8F4FD),
      ('just start.', CardStyle.textOnly, 0xFF0E2A3A, 0xFFE8F4FD),
      ('DREAM BIG,\nWORK HARD', CardStyle.outline, 0xFF0E2A3A, 0xFF6BAED6),
      ('2026', CardStyle.stamp, 0xFF1A3D5C, 0xFFC8A97E),
      ('learn · grow\n· explore', CardStyle.retro, 0xFF0E2A3A, 0xFF6BAED6),
      ('the world\nis yours.', CardStyle.handwritten, 0xFF1A3D5C, 0xFFE8F4FD),
      ('NO LIMITS', CardStyle.torn, 0xFF0E2A3A, 0xFFE8F4FD),
    ],
  };

  static final moodBackgrounds = {
    'manifestation': BoardBackground(
      type: BgType.gradient,
      color1: 0xFF12001f,
      color2: 0xFF0a0a0a,
      color3: 0xFF1a0a2e,
      useColor3: true,
    ),
    'soft_life': BoardBackground(
      type: BgType.dots,
      color1: 0xFFF7EFE5,
      color2: 0xFFD4C4B0,
      patternSize: 22,
    ),
    'that_girl': BoardBackground(
      type: BgType.grid,
      color1: 0xFF080808,
      color2: 0xFF1e1e1e,
      patternSize: 28,
    ),
    'cyber_dream': BoardBackground(
      type: BgType.gradient,
      color1: 0xFF0d0520,
      color2: 0xFF0a1a33,
      color3: 0xFF1a0533,
      useColor3: true,
    ),
    'wanderlust': BoardBackground(
      type: BgType.lines,
      color1: 0xFF0E2A3A,
      color2: 0xFF1A3D5C,
      patternSize: 28,
    ),
  };

  // ★ 배경 이미지 - 네가 준 파일명 그대로
  static const moodBgImages = {
    'manifestation': [
      'background/Manifestation/background4.png',
      'background/Manifestation/background6.jpg',
      'background/Manifestation/background7.jpg',
    ],
    'soft_life': ['background/soft_life/background8.jpg'],
    'that_girl': ['background/That_Girl/a45377159b7125d0814865662b707503.jpg'],
    'cyber_dream': [
      'background/Cyber_Dream/07d9b0f903868b69fcaf527d4bd15bdb.jpg',
      'background/Cyber_Dream/background9.jpg',
      'background/Cyber_Dream/background10.jpg',
      'background/Cyber_Dream/background11.jpg',
      'background/Cyber_Dream/background12.jpg',
      'background/Cyber_Dream/background13.jpg',
      'background/Cyber_Dream/background14.jpg',
    ],
    'wanderlust': [
      'background/wanderlust/background1.jpg',
      'background/wanderlust/background2.jpg',
      'background/wanderlust/background3.jpg',
      'background/wanderlust/background5.jpg',
    ],
  };

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _neonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadBoard();
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatController.dispose();
    _neonController.dispose();
    super.dispose();
  }

  void _updateFloatSpeed() {
    final duration = Duration(
      milliseconds: (_floatSpeedSeconds * 1000).round(),
    );
    _floatController.stop();
    _floatController.duration = duration;
    _floatController.repeat(reverse: true);
  }

  void _initFloatOffsets() {
    final rng = Random(42);
    _floatOffsets.clear();
    for (int i = 0; i < cards.length; i++)
      _floatOffsets.add(rng.nextDouble() * pi * 2);
  }

  void _startIntroAnimation() {
    if (_animStarted) return;
    _animStarted = true;
    _introController.reset();
    _introController.forward();
  }

  Future<void> _loadBoard() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBg = prefs.getString('board_background');
    if (savedBg != null)
      background = BoardBackground.fromJson(jsonDecode(savedBg));
    final saved = prefs.getString('board_cards');
    if (saved != null) {
      final List<dynamic> jsonList = jsonDecode(saved);
      setState(() {
        cards = jsonList.map((e) => BoardCard.fromJson(e)).toList();
        isLoading = false;
      });
      _initFloatOffsets();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateDefaultBoard();
        setState(() => isLoading = false);
        _initFloatOffsets();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _startIntroAnimation();
      });
    });
  }

  Future<void> _saveBoard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'board_cards',
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
    await prefs.setString('board_background', jsonEncode(background.toJson()));
  }

  Future<void> _exportAsPng() async {
    setState(() => _isExporting = true);
    try {
      setState(() => selectedIndex = null);
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary =
          _boardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      _downloadBytes(byteData.buffer.asUint8List(), 'vision_board.png');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved as PNG! 🎨'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF1a1a1a),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _downloadBytes(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text(
          'Export Board',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose export format:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _exportAsPng();
              },
              child: Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: Colors.white, size: 28),
                    SizedBox(height: 6),
                    Text(
                      'PNG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'High quality',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showMoodDialog() {
    final moods = [
      {
        'key': 'manifestation',
        'label': '✨ Manifestation',
        'desc': '야망 · 성공 · 드라마틱',
      },
      {'key': 'soft_life', 'label': '🌿 Soft Life', 'desc': '힐링 · 여유 · 따뜻함'},
      {'key': 'that_girl', 'label': '💪 That Girl', 'desc': '규율 · 성장 · 미니멀'},
      {
        'key': 'cyber_dream',
        'label': '🌀 Cyber Dream',
        'desc': '사이버 · 미래 · 비현실',
      },
      {'key': 'wanderlust', 'label': '🌍 Wanderlust', 'desc': '여행 · 자유 · 클래식'},
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text(
          'Choose Your Mood',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: moods
              .map(
                (mood) => GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyMood(mood['key']!);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mood['label']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mood['desc']!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _applyMood(String moodKey) {
    final rng = Random(DateTime.now().millisecondsSinceEpoch);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final newCards = <BoardCard>[];
    final placedRects = <Rect>[];

    final images = moodKey == 'manifestation'
        ? defaultImages
        : (moodImages[moodKey] ?? defaultImages);
    final shuffled = [...images]..shuffle(rng);
    final useImages = shuffled.take(min(shuffled.length, 20)).toList();

    for (int i = 0; i < useImages.length; i++) {
      final cwR = 0.08 + rng.nextDouble() * 0.06;
      final chR = 0.08 + rng.nextDouble() * 0.06;
      Offset? placed;
      for (int attempt = 0; attempt < 300; attempt++) {
        final xR = 0.01 + rng.nextDouble() * (0.98 - cwR);
        final yR = 0.01 + rng.nextDouble() * (0.98 - chR);
        final rect = Rect.fromLTWH(
          xR * screenW,
          yR * screenH,
          cwR * screenW,
          chR * screenW,
        );
        if (!placedRects.any((r) => _overlaps(r, rect))) {
          placed = Offset(xR, yR);
          placedRects.add(rect);
          break;
        }
      }
      placed ??= Offset(
        0.01 + rng.nextDouble() * (0.98 - cwR),
        0.01 + rng.nextDouble() * (0.98 - chR),
      );
      newCards.add(
        BoardCard(
          imageUrl: useImages[i],
          xRatio: placed.dx,
          yRatio: placed.dy,
          widthRatio: cwR,
          heightRatio: chR,
          rotation: (rng.nextDouble() - 0.5) * 0.45,
        ),
      );
    }

    final textItems = moodTextSets[moodKey]!;
    const txtCols = 4;
    const txtRows = 2;
    final zoneOrder = List.generate(txtCols * txtRows, (i) => i)..shuffle(rng);
    for (int i = 0; i < textItems.length; i++) {
      final (text, style, paperColor, textColor) = textItems[i];
      final cwR = 0.10 + rng.nextDouble() * 0.05;
      final chR = 0.07 + rng.nextDouble() * 0.04;
      final zoneIdx = zoneOrder[i % zoneOrder.length];
      final zoneLeft = (zoneIdx % txtCols) / txtCols;
      final zoneTop = (zoneIdx ~/ txtCols) / txtRows;
      final zoneW = 1.0 / txtCols;
      final zoneH = 1.0 / txtRows;
      Offset? placed;
      for (int attempt = 0; attempt < 500; attempt++) {
        final xR =
            zoneLeft +
            0.01 +
            rng.nextDouble() * (zoneW - cwR - 0.01).clamp(0, 1.0);
        final yR =
            zoneTop +
            0.01 +
            rng.nextDouble() * (zoneH - chR - 0.01).clamp(0, 1.0);
        final rect = Rect.fromLTWH(
          xR * screenW,
          yR * screenH,
          cwR * screenW,
          chR * screenW,
        );
        if (!placedRects.any((r) => _overlaps(r, rect))) {
          placed = Offset(xR, yR);
          placedRects.add(rect);
          break;
        }
      }
      placed ??= Offset(zoneLeft + 0.01, zoneTop + 0.01);
      newCards.add(
        BoardCard(
          text: text,
          xRatio: placed.dx,
          yRatio: placed.dy,
          widthRatio: cwR,
          heightRatio: chR,
          rotation: (rng.nextDouble() - 0.5) * 0.35,
          style: style,
          paperColor: paperColor,
          textColor: textColor,
        ),
      );
    }

    final bgImageList = moodBgImages[moodKey] ?? [];
    final randomBgAsset = bgImageList.isNotEmpty
        ? bgImageList[rng.nextInt(bgImageList.length)]
        : null;
    BoardBackground newBg;
    if (randomBgAsset != null) {
      newBg = BoardBackground(
        type: BgType.image,
        imageAsset: randomBgAsset,
        color1: 0xFF0a0a0a,
      );
    } else {
      final fallback = moodBackgrounds[moodKey]!;
      newBg = BoardBackground(
        type: fallback.type,
        color1: fallback.color1,
        color2: fallback.color2,
        color3: fallback.color3,
        useColor3: fallback.useColor3,
        patternSize: fallback.patternSize,
      );
    }

    setState(() {
      cards = newCards;
      background = newBg;
      selectedIndex = null;
      _animStarted = false;
      _currentMood = moodKey;
    });
    _initFloatOffsets();
    _updateFloatSpeed();
    _saveBoard();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _startIntroAnimation();
    });
  }

  Future<String?> _pickBgImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return null;
    final bytes = result.files.first.bytes;
    if (bytes == null) return null;
    return base64Encode(bytes);
  }

  void _showBgDialog() {
    BgType selectedType = background.type;
    Color selectedColor1 = Color(background.color1);
    Color selectedColor2 = Color(background.color2);
    Color selectedColor3 = Color(background.color3);
    bool useColor3 = background.useColor3;
    double patternSize = background.patternSize;
    String? selectedImageBase64 = background.imageBase64;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1a1a1a),
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Background',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final b64 = await _pickBgImage();
                      if (b64 != null)
                        setDialogState(() {
                          selectedType = BgType.image;
                          selectedImageBase64 = b64;
                        });
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: selectedType == BgType.image
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedType == BgType.image
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wallpaper,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedType == BgType.image &&
                                    selectedImageBase64 != null
                                ? 'Image uploaded ✓ (tap to change)'
                                : 'Upload Background Image',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedType == BgType.image &&
                      selectedImageBase64 != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setDialogState(() {
                        selectedType = BgType.solid;
                        selectedImageBase64 = null;
                      }),
                      child: const Row(
                        children: [
                          Icon(Icons.close, color: Colors.grey, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Remove image',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Presets',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: bgPresets.length,
                      itemBuilder: (ctx, i) {
                        final presetBg = bgPresets[i]['bg'] as BoardBackground;
                        return GestureDetector(
                          onTap: () => setDialogState(() {
                            selectedType = presetBg.type;
                            selectedColor1 = Color(presetBg.color1);
                            selectedColor2 = Color(presetBg.color2);
                            selectedColor3 = Color(presetBg.color3);
                            useColor3 = presetBg.useColor3;
                            patternSize = presetBg.patternSize;
                            selectedImageBase64 = null;
                          }),
                          child: Container(
                            width: 56,
                            height: 56,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: CustomPaint(
                                size: const Size(56, 56),
                                painter: BackgroundPainter(presetBg),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedType != BgType.image) ...[
                    const Text(
                      'Pattern',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: BgType.values
                          .where((t) => t != BgType.image)
                          .map((t) {
                            final isSel = selectedType == t;
                            return GestureDetector(
                              onTap: () =>
                                  setDialogState(() => selectedType = t),
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
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  bgTypeLabels[t]!,
                                  style: TextStyle(
                                    color: isSel ? Colors.black : Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Color 1',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final p = await _showColorPickerDialog(
                                    ctx,
                                    selectedColor1,
                                    'Color 1',
                                  );
                                  if (p != null)
                                    setDialogState(() => selectedColor1 = p);
                                },
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: selectedColor1,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.colorize,
                                      color:
                                          selectedColor1.computeLuminance() >
                                              0.5
                                          ? Colors.black54
                                          : Colors.white54,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedType == BgType.gradient
                                    ? 'Color 2'
                                    : 'Pattern Color',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final p = await _showColorPickerDialog(
                                    ctx,
                                    selectedColor2,
                                    'Color 2',
                                  );
                                  if (p != null)
                                    setDialogState(() => selectedColor2 = p);
                                },
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: selectedColor2,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.colorize,
                                      color:
                                          selectedColor2.computeLuminance() >
                                              0.5
                                          ? Colors.black54
                                          : Colors.white54,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedType == BgType.gradient) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Color 3',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => setDialogState(
                                        () => useColor3 = !useColor3,
                                      ),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: useColor3
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        child: useColor3
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Colors.black,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: useColor3
                                      ? () async {
                                          final p =
                                              await _showColorPickerDialog(
                                                ctx,
                                                selectedColor3,
                                                'Color 3',
                                              );
                                          if (p != null)
                                            setDialogState(
                                              () => selectedColor3 = p,
                                            );
                                        }
                                      : null,
                                  child: Opacity(
                                    opacity: useColor3 ? 1.0 : 0.3,
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: selectedColor3,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.colorize,
                                          color:
                                              selectedColor3
                                                      .computeLuminance() >
                                                  0.5
                                              ? Colors.black54
                                              : Colors.white54,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (selectedType != BgType.solid &&
                        selectedType != BgType.gradient) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Pattern Size',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: patternSize,
                              min: 10,
                              max: 60,
                              divisions: 10,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                              onChanged: (v) =>
                                  setDialogState(() => patternSize = v),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${patternSize.round()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Preview',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 100,
                      width: double.infinity,
                      child:
                          selectedType == BgType.image &&
                              selectedImageBase64 != null
                          ? Image.memory(
                              base64Decode(selectedImageBase64!),
                              fit: BoxFit.cover,
                            )
                          : CustomPaint(
                              size: const Size(double.infinity, 100),
                              painter: BackgroundPainter(
                                BoardBackground(
                                  type: selectedType,
                                  color1: selectedColor1.value,
                                  color2: selectedColor2.value,
                                  color3: selectedColor3.value,
                                  useColor3: useColor3,
                                  patternSize: patternSize,
                                ),
                              ),
                            ),
                    ),
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
                          setState(() {
                            background = BoardBackground(
                              type: selectedType,
                              color1: selectedColor1.value,
                              color2: selectedColor2.value,
                              color3: selectedColor3.value,
                              useColor3: useColor3,
                              patternSize: patternSize,
                              imageBase64: selectedImageBase64,
                            );
                          });
                          _saveBoard();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Apply',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Color?> _showColorPickerDialog(
    BuildContext context,
    Color initial,
    String title,
  ) async {
    Color picked = initial;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            onColorChanged: (c) => picked = c,
            enableAlpha: true,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, picked),
            child: const Text('OK', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _generateDefaultBoard() {
    final rng = Random(56);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final placedRects = <Rect>[];
    final newCards = <BoardCard>[];
    const centerImgPath =
        'imgs/Manifestation/87c88cb11e2f37df0fd2b4134692dbf2.jpg';
    const centerWR = 0.18;
    const centerHR = 0.18;
    final centerXR = (1.0 - centerWR) / 2;
    final centerYR = (1.0 - centerHR) / 2 - 0.02;
    placedRects.add(
      Rect.fromLTWH(
        centerXR * screenW,
        centerYR * screenH,
        centerWR * screenW,
        centerHR * screenW,
      ),
    );
    final topForced = [
      Offset(rng.nextDouble() * 0.25, 0.01 + rng.nextDouble() * 0.12),
      Offset(0.25 + rng.nextDouble() * 0.25, 0.01 + rng.nextDouble() * 0.12),
      Offset(0.5 + rng.nextDouble() * 0.25, 0.01 + rng.nextDouble() * 0.12),
      Offset(0.75 + rng.nextDouble() * 0.2, 0.01 + rng.nextDouble() * 0.12),
    ];
    int topCount = 0;
    for (final img in defaultImages) {
      if (img == centerImgPath) continue;
      final cwR = 0.08 + rng.nextDouble() * 0.06;
      final chR = 0.08 + rng.nextDouble() * 0.06;
      Offset? placed;
      if (topCount < 4) {
        placed = topForced[topCount++];
        placedRects.add(
          Rect.fromLTWH(
            placed.dx * screenW,
            placed.dy * screenH,
            cwR * screenW,
            chR * screenW,
          ),
        );
      } else {
        for (int attempt = 0; attempt < 300; attempt++) {
          final xR = 0.01 + rng.nextDouble() * (0.98 - cwR);
          final yR = 0.01 + rng.nextDouble() * (0.98 - chR);
          final rect = Rect.fromLTWH(
            xR * screenW,
            yR * screenH,
            cwR * screenW,
            chR * screenW,
          );
          if (!placedRects.any((r) => _overlaps(r, rect))) {
            placed = Offset(xR, yR);
            placedRects.add(rect);
            break;
          }
        }
      }
      placed ??= Offset(
        0.01 + rng.nextDouble() * (0.98 - cwR),
        0.01 + rng.nextDouble() * (0.98 - chR),
      );
      newCards.add(
        BoardCard(
          imageUrl: img,
          xRatio: placed.dx,
          yRatio: placed.dy,
          widthRatio: cwR,
          heightRatio: chR,
          rotation: (rng.nextDouble() - 0.5) * 0.45,
        ),
      );
    }
    newCards.add(
      BoardCard(
        imageUrl: centerImgPath,
        xRatio: centerXR,
        yRatio: centerYR,
        widthRatio: centerWR,
        heightRatio: centerHR,
        rotation: 0,
      ),
    );
    final textItems = moodTextSets['manifestation']!;
    const txtCols = 4;
    const txtRows = 2;
    final zoneOrder = List.generate(txtCols * txtRows, (i) => i)
      ..shuffle(Random(77));
    for (int i = 0; i < textItems.length; i++) {
      final (text, style, paperColor, textColor) = textItems[i];
      final cwR = 0.10 + rng.nextDouble() * 0.05;
      final chR = 0.07 + rng.nextDouble() * 0.04;
      final zoneIdx = zoneOrder[i % zoneOrder.length];
      final zoneLeft = (zoneIdx % txtCols) / txtCols;
      final zoneTop = (zoneIdx ~/ txtCols) / txtRows;
      final zoneW = 1.0 / txtCols;
      final zoneH = 1.0 / txtRows;
      Offset? placed;
      for (int attempt = 0; attempt < 500; attempt++) {
        final xR =
            zoneLeft +
            0.01 +
            rng.nextDouble() * (zoneW - cwR - 0.01).clamp(0, 1.0);
        final yR =
            zoneTop +
            0.01 +
            rng.nextDouble() * (zoneH - chR - 0.01).clamp(0, 1.0);
        final rect = Rect.fromLTWH(
          xR * screenW,
          yR * screenH,
          cwR * screenW,
          chR * screenW,
        );
        if (!placedRects.any((r) => _overlaps(r, rect))) {
          placed = Offset(xR, yR);
          placedRects.add(rect);
          break;
        }
      }
      placed ??= Offset(zoneLeft + 0.01, zoneTop + 0.01);
      newCards.add(
        BoardCard(
          text: text,
          xRatio: placed.dx,
          yRatio: placed.dy,
          widthRatio: cwR,
          heightRatio: chR,
          rotation: (rng.nextDouble() - 0.5) * 0.45,
          style: style,
          paperColor: paperColor,
          textColor: textColor,
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
          xRatio: 0.05 + rng.nextDouble() * 0.1,
          yRatio: 0.05 + rng.nextDouble() * 0.1,
          widthRatio: 0.12 + rng.nextDouble() * 0.05,
          heightRatio: 0.12 + rng.nextDouble() * 0.05,
          rotation: (rng.nextDouble() - 0.5) * 0.3,
        ),
      );
      _floatOffsets.add(rng.nextDouble() * pi * 2);
    });
    _saveBoard();
  }

  void _showTextDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final card = isEdit ? cards[editIndex] : null;
    final controller = TextEditingController(text: card?.text ?? '');
    CardStyle selectedStyle = card?.style ?? CardStyle.torn;
    Color selectedPaperColor = Color(card?.paperColor ?? 0xFFF5F0E8);
    Color selectedTextColor = Color(card?.textColor ?? 0xFF1a1a1a);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1a1a1a),
          child: Container(
            width: 600,
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
                          const SizedBox(height: 12),
                          const Text(
                            'Style',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children:
                                [
                                  CardStyle.torn,
                                  CardStyle.tornMore,
                                  CardStyle.lined,
                                  CardStyle.textOnly,
                                  CardStyle.stamp,
                                  CardStyle.handwritten,
                                ].map((s) {
                                  final isSel = selectedStyle == s;
                                  return GestureDetector(
                                    onTap: () =>
                                        setDialogState(() => selectedStyle = s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? Colors.white
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        styleLabels[s]!,
                                        style: TextStyle(
                                          color: isSel
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Special FX',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children:
                                [
                                  CardStyle.neon,
                                  CardStyle.hologram,
                                  CardStyle.bubble,
                                  CardStyle.outline,
                                  CardStyle.retro,
                                  CardStyle.glitch,
                                  CardStyle.chrome,
                                  CardStyle.rainbow,
                                ].map((s) {
                                  final isSel = selectedStyle == s;
                                  return GestureDetector(
                                    onTap: () =>
                                        setDialogState(() => selectedStyle = s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? Colors.white
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        styleLabels[s]!,
                                        style: TextStyle(
                                          color: isSel
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Text Color',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: presetTextColors
                                      .map(
                                        (c) => GestureDetector(
                                          onTap: () => setDialogState(
                                            () => selectedTextColor = c,
                                          ),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: c,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: selectedTextColor == c
                                                    ? Colors.white
                                                    : Colors.grey.withOpacity(
                                                        0.4,
                                                      ),
                                                width: 2,
                                              ),
                                            ),
                                            child: selectedTextColor == c
                                                ? Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color:
                                                        c.computeLuminance() >
                                                            0.5
                                                        ? Colors.black
                                                        : Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final p = await _showColorPickerDialog(
                                    ctx,
                                    selectedTextColor,
                                    'Text Color',
                                  );
                                  if (p != null)
                                    setDialogState(() => selectedTextColor = p);
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: selectedTextColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.colorize,
                                    size: 18,
                                    color:
                                        selectedTextColor.computeLuminance() >
                                            0.5
                                        ? Colors.black54
                                        : Colors.white54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 160,
                          height: 200,
                          color: const Color(0xFF0a0a0a),
                          child: Center(
                            child: _buildSpecialTextCard(
                              text: controller.text.isEmpty
                                  ? 'Preview'
                                  : controller.text,
                              style: selectedStyle,
                              textColor: selectedTextColor,
                              paperColor: selectedPaperColor,
                              w: 150,
                              h: 80,
                              neonFlicker: 1.0,
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
                          final rng = Random();
                          setState(() {
                            if (isEdit) {
                              cards[editIndex].text = controller.text;
                              cards[editIndex].style = selectedStyle;
                              cards[editIndex].paperColor =
                                  selectedPaperColor.value;
                              cards[editIndex].textColor =
                                  selectedTextColor.value;
                            } else {
                              cards.add(
                                BoardCard(
                                  text: controller.text,
                                  xRatio: 0.05,
                                  yRatio: 0.05,
                                  widthRatio: 0.13,
                                  heightRatio: 0.09,
                                  rotation: (rng.nextDouble() - 0.5) * 0.3,
                                  style: selectedStyle,
                                  paperColor: selectedPaperColor.value,
                                  textColor: selectedTextColor.value,
                                ),
                              );
                              _floatOffsets.add(rng.nextDouble() * pi * 2);
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

  void _deleteCard(int index) {
    setState(() {
      cards.removeAt(index);
      if (index < _floatOffsets.length) _floatOffsets.removeAt(index);
      selectedIndex = null;
    });
    _saveBoard();
  }

  void _bringForward(int index) {
    if (index < cards.length - 1) {
      setState(() {
        final c = cards.removeAt(index);
        cards.insert(index + 1, c);
        if (index < _floatOffsets.length) {
          final o = _floatOffsets.removeAt(index);
          _floatOffsets.insert(index + 1, o);
        }
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
        if (index < _floatOffsets.length) {
          final o = _floatOffsets.removeAt(index);
          _floatOffsets.insert(index - 1, o);
        }
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
              await prefs.remove('board_background');
              setState(() {
                cards = [];
                selectedIndex = null;
                _animStarted = false;
                background = BoardBackground();
                _currentMood = 'manifestation';
              });
              _generateDefaultBoard();
              _initFloatOffsets();
              _updateFloatSpeed();
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _startIntroAnimation();
              });
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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

  List<Widget> _buildControls(
    BoardCard card,
    int index,
    double screenW,
    double screenH,
  ) {
    final left = card.x(screenW);
    final top = card.y(screenH);
    final right = left + card.width(screenW);
    final bottom = top + card.height(screenW) + 24;
    return [
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
      Positioned(
        left: right - 14,
        top: bottom - 14,
        child: _handle(
          icon: Icons.open_in_full,
          bg: Colors.white,
          iconColor: Colors.black,
          onPanUpdate: (d) => setState(() {
            card.widthRatio = ((card.width(screenW) + d.delta.dx) / screenW)
                .clamp(0.05, 0.6);
            card.heightRatio = ((card.height(screenW) + d.delta.dy) / screenW)
                .clamp(0.03, 0.6);
          }),
          onPanEnd: (_) => _saveBoard(),
        ),
      ),
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

  Widget _buildBackground() {
    if (background.type == BgType.image) {
      if (background.imageBase64 != null)
        return Image.memory(
          base64Decode(background.imageBase64!),
          fit: BoxFit.cover,
        );
      if (background.imageAsset != null)
        return Image.asset(background.imageAsset!, fit: BoxFit.cover);
    }
    return CustomPaint(painter: BackgroundPainter(background));
  }

  // ★ 무드별 완전 다른 인트로 애니메이션 계산
  Map<String, double> _calcIntroValues(
    int index,
    int total,
    double animValue,
    double screenW,
    double screenH,
    BoardCard card,
  ) {
    final floatOffset = index < _floatOffsets.length
        ? _floatOffsets[index]
        : 0.0;

    switch (_currentMood) {
      // ✨ Manifestation: 사방에서 날아와서 쾅 박히는 느낌
      case 'manifestation':
        {
          final progress = total <= 1 ? 0.0 : index / (total - 1);
          final delay = (progress * 0.6).clamp(0.0, 0.6);
          final end = (delay + 0.35).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);
          final curved = _StickerCurve().transform(t);
          final angle = floatOffset * 2 - pi; // 사방에서 날아오는 방향
          final dist = (1.0 - curved) * 400.0;
          return {
            'opacity': Curves.easeIn.transform(t.clamp(0.0, 1.0)),
            'scale': curved.clamp(0.0, 1.3),
            'dx': cos(angle) * dist,
            'dy': sin(angle) * dist,
            'rotate':
                card.rotation + (1.0 - curved) * (index.isEven ? 0.5 : -0.5),
          };
        }

      // 🌿 Soft Life: 위에서 천천히 낙엽처럼 떨어지는 느낌
      case 'soft_life':
        {
          final progress = total <= 1 ? 0.0 : index / (total - 1);
          final delay = (progress * 0.7).clamp(0.0, 0.7);
          final end = (delay + 0.3).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);
          final curved = Curves.easeInOutSine.transform(t);
          final fallDist = (1.0 - curved) * 300.0;
          final sway = sin(t * pi * 2 + floatOffset) * 20.0 * (1.0 - curved);
          return {
            'opacity': t < 0.3 ? t / 0.3 : 1.0,
            'scale': 0.7 + curved * 0.3,
            'dx': sway,
            'dy': -fallDist,
            'rotate': card.rotation + (1.0 - curved) * sin(floatOffset) * 0.15,
          };
        }

      // 💪 That Girl: 좌→우 순서대로 딱딱 나타남
      case 'that_girl':
        {
          // 격자 위치 기반으로 열 순서 계산
          final col = (card.xRatio * 4).floor().clamp(0, 3);
          final row = (card.yRatio * 3).floor().clamp(0, 2);
          final order = row * 4 + col;
          final delay = (order / 12.0 * 0.7).clamp(0.0, 0.7);
          final end = (delay + 0.15).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);
          final curved = Curves.easeOutCubic.transform(t);
          return {
            'opacity': curved,
            'scale': 0.85 + curved * 0.15,
            'dx': 0.0,
            'dy': 0.0,
            'rotate': card.rotation,
          };
        }

      // 🌀 Cyber Dream: 위치가 막 튀었다가 글리치처럼 안착
      case 'cyber_dream':
        {
          final progress = total <= 1 ? 0.0 : index / (total - 1);
          final delay = (progress * 0.4).clamp(0.0, 0.4);
          final end = (delay + 0.5).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);

          // 글리치: t 구간별로 위치가 튐
          double glitchX = 0.0;
          double glitchY = 0.0;
          double glitchOpacity = 0.0;

          if (t < 0.15) {
            // 처음엔 안 보임
            glitchOpacity = 0.0;
          } else if (t < 0.3) {
            // 1차 글리치 - 엉뚱한 위치에 잠깐 나타남
            glitchOpacity = 0.7;
            glitchX = sin(floatOffset * 5) * 120.0;
            glitchY = cos(floatOffset * 3) * 80.0;
          } else if (t < 0.45) {
            // 잠깐 사라짐
            glitchOpacity = 0.2;
            glitchX = -sin(floatOffset * 4) * 60.0;
            glitchY = cos(floatOffset * 2) * 40.0;
          } else if (t < 0.6) {
            // 2차 글리치 - 다른 위치에 나타남
            glitchOpacity = 0.9;
            glitchX = cos(floatOffset * 3) * 40.0;
            glitchY = sin(floatOffset * 5) * 30.0;
          } else {
            // 제자리에 안착
            final settle = Curves.easeOutExpo.transform((t - 0.6) / 0.4);
            glitchOpacity = settle;
            glitchX = cos(floatOffset * 3) * 40.0 * (1.0 - settle);
            glitchY = sin(floatOffset * 5) * 30.0 * (1.0 - settle);
          }

          return {
            'opacity': glitchOpacity,
            'scale': t < 0.6
                ? 0.9
                : (0.9 + Curves.easeOutExpo.transform((t - 0.6) / 0.4) * 0.1),
            'dx': glitchX,
            'dy': glitchY,
            'rotate': card.rotation + (t < 0.6 ? sin(t * pi * 6) * 0.1 : 0.0),
          };
        }

      // 🌍 Wanderlust: 아래에서 안개처럼 서서히 떠오름
      case 'wanderlust':
        {
          final progress = total <= 1 ? 0.0 : index / (total - 1);
          final delay = (progress * 0.65).clamp(0.0, 0.65);
          final end = (delay + 0.35).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);
          final curved = Curves.easeOutQuart.transform(t);

          // 아래에서 위로 떠오름 + 페이드인
          final riseDist = (1.0 - curved) * 150.0;
          // 살짝 좌우 흔들림 (바람 느낌)
          final sway = sin(t * pi * 1.5 + floatOffset) * 12.0 * (1.0 - curved);

          return {
            'opacity': t < 0.4 ? Curves.easeIn.transform(t / 0.4) : 1.0,
            'scale': 0.85 + curved * 0.15,
            'dx': sway,
            'dy': riseDist, // 양수 = 아래에서 시작 → 위로
            'rotate': card.rotation + (1.0 - curved) * sin(floatOffset) * 0.1,
          };
        }

      default:
        {
          final progress = total <= 1 ? 0.0 : index / (total - 1);
          final delay = (progress * 0.65).clamp(0.0, 0.65);
          final end = (delay + 0.3).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);
          final curved = _StickerCurve().transform(t);
          return {
            'opacity': Curves.easeIn.transform(t.clamp(0.0, 1.0)),
            'scale': curved.clamp(0.0, 1.3),
            'dx': 0.0,
            'dy': 0.0,
            'rotate':
                card.rotation +
                (1.0 - t.clamp(0.0, 1.0)) * (index.isEven ? 0.2 : -0.2),
          };
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;

          return GestureDetector(
            onTap: () => setState(() => selectedIndex = null),
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                RepaintBoundary(
                  key: _boardKey,
                  child: SizedBox(
                    width: screenW,
                    height: screenH,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildBackground()),
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _introController,
                            _floatController,
                            _neonController,
                          ]),
                          builder: (context, _) {
                            return Stack(
                              children: List.generate(cards.length, (index) {
                                final card = cards[index];
                                final isSelected = selectedIndex == index;
                                final px = card.x(screenW);
                                final py = card.y(screenH);
                                final pw = card.width(screenW);
                                final ph = card.height(screenW);
                                final total = cards.length.clamp(1, 9999);
                                final floatOffset = index < _floatOffsets.length
                                    ? _floatOffsets[index]
                                    : 0.0;

                                // ★ 무드별 인트로 값 계산
                                final iv = _calcIntroValues(
                                  index,
                                  total,
                                  _introController.value,
                                  screenW,
                                  screenH,
                                  card,
                                );
                                final opacity = (iv['opacity']! as double)
                                    .clamp(0.0, 1.0);
                                final scale = (iv['scale']! as double).clamp(
                                  0.0,
                                  1.5,
                                );
                                final introDx = iv['dx']! as double;
                                final introDy = iv['dy']! as double;
                                final introRotate = iv['rotate']! as double;

                                // 플로팅 (인트로 끝난 후)
                                final introProgress = _introController.value;
                                final floatBlend = opacity.clamp(0.0, 1.0);
                                final floatY = isSelected
                                    ? 0.0
                                    : sin(
                                            _floatController.value * pi +
                                                floatOffset,
                                          ) *
                                          _floatAmplitude *
                                          floatBlend;
                                final floatRot = isSelected
                                    ? 0.0
                                    : sin(
                                            _floatController.value * pi +
                                                floatOffset +
                                                1.0,
                                          ) *
                                          0.008 *
                                          floatBlend;

                                // 네온 깜빡임
                                final neonFlicker = card.style == CardStyle.neon
                                    ? _neonIntensityBase +
                                          sin(
                                                _neonController.value * pi * 2 +
                                                    floatOffset,
                                              ) *
                                              (1.0 - _neonIntensityBase)
                                    : 1.0;

                                return Positioned(
                                  left: px + introDx,
                                  top: py + introDy + floatY,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(
                                      () => selectedIndex =
                                          selectedIndex == index ? null : index,
                                    ),
                                    onDoubleTap: () {
                                      if (card.text != null)
                                        _showTextDialog(editIndex: index);
                                    },
                                    onPanUpdate: (d) {
                                      setState(() {
                                        card.xRatio =
                                            ((card.xRatio * screenW +
                                                        d.delta.dx) /
                                                    screenW)
                                                .clamp(0.0, 1.0);
                                        card.yRatio =
                                            ((card.yRatio * screenH +
                                                        d.delta.dy) /
                                                    screenH)
                                                .clamp(0.0, 1.0);
                                      });
                                    },
                                    onPanEnd: (_) => _saveBoard(),
                                    child: Opacity(
                                      opacity: opacity,
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Transform.rotate(
                                          angle: introRotate + floatRot,
                                          child:
                                              card.imageUrl != null ||
                                                  card.imageBase64 != null
                                              ? _buildPhotoCard(card, pw, ph)
                                              : _buildSpecialTextCard(
                                                  text: card.text!,
                                                  style: card.style,
                                                  textColor: Color(
                                                    card.textColor,
                                                  ),
                                                  paperColor: Color(
                                                    card.paperColor,
                                                  ),
                                                  w: pw,
                                                  h: ph,
                                                  neonFlicker: neonFlicker,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                if (selectedIndex != null && selectedIndex! < cards.length)
                  ..._buildControls(
                    cards[selectedIndex!],
                    selectedIndex!,
                    screenW,
                    screenH,
                  ),

                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _toolbarButton(
                        Icons.auto_awesome,
                        'Mood',
                        _showMoodDialog,
                      ),
                      const SizedBox(width: 10),
                      _toolbarButton(Icons.upload_file, 'Upload', _pickImage),
                      const SizedBox(width: 10),
                      _toolbarButton(
                        Icons.text_fields,
                        'Text',
                        () => _showTextDialog(),
                      ),
                      const SizedBox(width: 10),
                      _toolbarButton(Icons.wallpaper, 'BG', _showBgDialog),
                      const SizedBox(width: 10),
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
                      const SizedBox(width: 10),
                      _isExporting
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _toolbarButton(
                              Icons.download,
                              'Export',
                              _showExportDialog,
                            ),
                      const SizedBox(width: 10),
                      _toolbarButton(Icons.refresh, 'Reset', _confirmReset),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoCard(BoardCard card, double w, double h) {
    return Container(
      width: w,
      height: h + 24,
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
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: child,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSpecialTextCard({
    required String text,
    required CardStyle style,
    required Color textColor,
    required Color paperColor,
    required double w,
    required double h,
    required double neonFlicker,
  }) {
    if (style == CardStyle.textOnly)
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: textColor,
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
    if (style == CardStyle.stamp)
      return Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: paperColor, width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      );
    if (style == CardStyle.handwritten)
      return Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.dancingScript(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 6),
            ],
          ),
        ),
      );
    if ([CardStyle.torn, CardStyle.tornMore, CardStyle.lined].contains(style))
      return SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          painter: TornPaperPainter(
            color: paperColor,
            seed: text.hashCode,
            style: style,
          ),
          child: Center(
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
                  color: textColor,
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
    if (style == CardStyle.neon)
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Opacity(
            opacity: neonFlicker.clamp(0.15, 1.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: textColor.withOpacity(0.9), blurRadius: 4),
                  Shadow(color: textColor.withOpacity(0.7), blurRadius: 10),
                  Shadow(color: textColor.withOpacity(0.4), blurRadius: 20),
                  Shadow(color: textColor.withOpacity(0.2), blurRadius: 40),
                ],
              ),
            ),
          ),
        ),
      );
    if (style == CardStyle.hologram)
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [
                Color(0xFFFF6EC7),
                Color(0xFFA78BFA),
                Color(0xFF60A5FA),
                Color(0xFF34D399),
                Color(0xFFFF6EC7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(b),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );
    if (style == CardStyle.bubble)
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(color: Colors.white.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    if (style == CardStyle.outline)
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.5
                    ..color = textColor,
                ),
              ),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      );
    if (style == CardStyle.retro) {
      final sc = HSLColor.fromColor(textColor)
          .withLightness(
            (HSLColor.fromColor(textColor).lightness * 0.5).clamp(0.0, 1.0),
          )
          .toColor();
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [
                Shadow(color: sc, offset: const Offset(1, 1)),
                Shadow(color: sc.withOpacity(0.8), offset: const Offset(2, 2)),
                Shadow(color: sc.withOpacity(0.6), offset: const Offset(3, 3)),
                Shadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(4, 4),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (style == CardStyle.glitch)
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(2.5, 0),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFF00FFFF).withOpacity(0.7),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(-2.5, 0),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFF0066).withOpacity(0.7),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    if (style == CardStyle.chrome)
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFF888888),
                Color(0xFFFFFFFF),
                Color(0xFF555555),
                Color(0xFFFFFFFF),
              ],
              stops: [0.0, 0.3, 0.5, 0.7, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(b),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      );
    if (style == CardStyle.rainbow)
      return Container(
        width: w,
        height: h,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6EC7),
              Color(0xFFA78BFA),
              Color(0xFF60A5FA),
              Color(0xFF34D399),
              Color(0xFFFBBF24),
              Color(0xFFFF6EC7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0a0a0a),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      );
    return SizedBox(
      width: w,
      height: h,
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 5),
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

class _StickerCurve extends Curve {
  const _StickerCurve();
  @override
  double transform(double t) {
    if (t < 0.6)
      return Curves.easeOut.transform(t / 0.6);
    else if (t < 0.75)
      return 1.0 + (t - 0.6) / 0.15 * 0.12;
    else if (t < 0.9)
      return 1.12 - (t - 0.75) / 0.15 * 0.16;
    else
      return 0.96 + (t - 0.9) / 0.1 * 0.04;
  }
}

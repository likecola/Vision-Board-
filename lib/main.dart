import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
import 'diagnosis.dart';
import 'diagnosis_data.dart';
import 'intro.dart';
import 'web_synth.dart';

// ★ 공유 링크 해시 — Flutter 라우터가 URL을 덮어쓰기 전에 main()에서 캡처
String initialUrlHash = '';

/// 보드 로딩이 끝나면 true — 인트로의 HELLO 단계 진입 조건.
final ValueNotifier<bool> appReadyNotifier = ValueNotifier<bool>(false);

void main() {
  initialUrlHash = html.window.location.hash;
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
      home: const IntroGate(),
    );
  }
}


/// 앱 위에 인트로를 덮어 보여주는 게이트.
/// - 공유 링크(#b=)로 들어온 방문자는 인트로 없이 바로 보드를 본다.
/// - 재방문자(intro_seen)만 SKIP(▸▸)/S 키를 쓸 수 있다.
/// - A(진단 시작)를 누르면 진단 모드를 열고 인트로를 페이드아웃한다.
class IntroGate extends StatefulWidget {
  const IntroGate({super.key});

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  final _pageKey = GlobalKey<_VisionBoardPageState>();
  // ?intro=0 으로 인트로를 건너뛸 수 있다 (임베드/개발용)
  late bool _showIntro =
      !initialUrlHash.startsWith('#b=') &&
      Uri.base.queryParameters['intro'] != '0';
  bool _returning = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _returning = p.getBool('intro_seen') ?? false);
    });
  }

  Future<void> _markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('intro_seen', true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        VisionBoardPage(key: _pageKey),
        if (_showIntro)
          IntroOverlay(
            appReady: appReadyNotifier,
            allowSkip: _returning,
            onStarted: _markSeen,
            onStartDiagnosis: () => _pageKey.currentState?._startQuiz(),
            onFinished: () => setState(() => _showIntro = false),
          ),
      ],
    );
  }
}

class MoodTheme {
  final Color deviceBg; // shell1
  final Color deviceBg2; // shell2
  final Color deviceBorder; // shellHi
  final Color screenBorder; // bezel
  final Color accent; // accent
  final Color accent2; // accent2
  final Color accentDim;
  final Color buttonBg; // btnFace
  final Color buttonBorder; // btnEdge
  final Color buttonTop;
  final Color buttonSide;
  final Color textPrimary; // text
  final Color textSecondary; // muted
  final Color cardFrame; // cardFrame
  final Color glowColor; // glow
  final Color vigColor; // vignette

  const MoodTheme({
    required this.deviceBg,
    required this.deviceBg2,
    required this.deviceBorder,
    required this.screenBorder,
    required this.accent,
    required this.accent2,
    required this.accentDim,
    required this.buttonBg,
    required this.buttonBorder,
    required this.buttonTop,
    required this.buttonSide,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardFrame,
    required this.glowColor,
    required this.vigColor,
  });
}

const moodThemes = {
  // ✨ Manifestation — 딥 퍼플/핑크, 화려하고 폭발적
  'manifestation': MoodTheme(
    deviceBg: Color(0xFF3a2566),
    deviceBg2: Color(0xFF1d1138),
    deviceBorder: Color(0xFF4e2f86),
    screenBorder: Color(0xFF0c0720),
    accent: Color(0xFFcf8bff),
    accent2: Color(0xFFff79c6),
    accentDim: Color(0xFF46298a),
    buttonBg: Color(0xFF46298a),
    buttonBorder: Color(0xFF241248),
    buttonTop: Color(0xFF5a3aa0),
    buttonSide: Color(0xFF160a30),
    textPrimary: Color(0xFFf3e8ff),
    textSecondary: Color(0xFFb79fdd),
    cardFrame: Color(0xFFece4f6),
    glowColor: Color(0x80cf8bff),
    vigColor: Color(0xA60a041e),
  ),
  // 🌿 Soft Life — 베이지/크림/테라코타
  'soft_life': MoodTheme(
    deviceBg: Color(0xFFe6d4b6),
    deviceBg2: Color(0xFFc3a87f),
    deviceBorder: Color(0xFFf1e4cd),
    screenBorder: Color(0xFF9c8059),
    accent: Color(0xFFb06a44),
    accent2: Color(0xFF7e8f5d),
    accentDim: Color(0xFFa87040),
    buttonBg: Color(0xFFd8c19c),
    buttonBorder: Color(0xFFa8865c),
    buttonTop: Color(0xFFe8d5b0),
    buttonSide: Color(0xFF8a6c42),
    textPrimary: Color(0xFF5a4733),
    textSecondary: Color(0xFF977f5e),
    cardFrame: Color(0xFFfcf7ec),
    glowColor: Color(0x73b06a44),
    vigColor: Color(0x66785f3c),
  ),
  // 💪 That Girl — 블랙/골드, 미니멀
  'that_girl': MoodTheme(
    deviceBg: Color(0xFF211e19),
    deviceBg2: Color(0xFF0c0b09),
    deviceBorder: Color(0xFF2f2a22),
    screenBorder: Color(0xFF000000),
    accent: Color(0xFFcba24f),
    accent2: Color(0xFFe7d29a),
    accentDim: Color(0xFF7a6230),
    buttonBg: Color(0xFF26221b),
    buttonBorder: Color(0xFF0c0b08),
    buttonTop: Color(0xFF322d24),
    buttonSide: Color(0xFF060504),
    textPrimary: Color(0xFFece5d6),
    textSecondary: Color(0xFF8a8270),
    cardFrame: Color(0xFF14120e),
    glowColor: Color(0x80cba24f),
    vigColor: Color(0xC8000000),
  ),
  // 🌀 Cyber Dream — 딥네이비/시안/핑크 네온
  'cyber_dream': MoodTheme(
    deviceBg: Color(0xFF0e1c3c),
    deviceBg2: Color(0xFF050a1c),
    deviceBorder: Color(0xFF1a3568),
    screenBorder: Color(0xFF01030c),
    accent: Color(0xFF2fe6ff),
    accent2: Color(0xFFff45e0),
    accentDim: Color(0xFF0a4060),
    buttonBg: Color(0xFF10254e),
    buttonBorder: Color(0xFF040a1c),
    buttonTop: Color(0xFF1a3060),
    buttonSide: Color(0xFF020610),
    textPrimary: Color(0xFFcdfbff),
    textSecondary: Color(0xFF5fa3cc),
    cardFrame: Color(0xFF06112a),
    glowColor: Color(0xBF2fe6ff),
    vigColor: Color(0xB202060f),
  ),
  // 🌍 Wanderlust — 딥틸/아쿠아
  'wanderlust': MoodTheme(
    deviceBg: Color(0xFF15414f),
    deviceBg2: Color(0xFF0a2330),
    deviceBorder: Color(0xFF1f6377),
    screenBorder: Color(0xFF06161d),
    accent: Color(0xFF52d6c8),
    accent2: Color(0xFF86bce0),
    accentDim: Color(0xFF1a5050),
    buttonBg: Color(0xFF134653),
    buttonBorder: Color(0xFF08222b),
    buttonTop: Color(0xFF1d5e6e),
    buttonSide: Color(0xFF040e14),
    textPrimary: Color(0xFFdff6f3),
    textSecondary: Color(0xFF7fb2b2),
    cardFrame: Color(0xFF08222b),
    glowColor: Color(0x8C52d6c8),
    vigColor: Color(0x99061e26),
  ),
};

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

// ★ 3D 버튼 위젯
class GameButton3D extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool isActive;
  final MoodTheme theme;
  final double fontSize;
  final bool isVertical;
  final IconData? icon;

  const GameButton3D({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 60,
    this.height = 30,
    this.isActive = false,
    required this.theme,
    this.fontSize = 8,
    this.isVertical = false,
    this.icon,
  });

  @override
  State<GameButton3D> createState() => _GameButton3DState();
}

class _GameButton3DState extends State<GameButton3D> {
  bool _pressed = false;
  static const _depth = 5.0;

  @override
  Widget build(BuildContext context) {
    final topColor = widget.isActive
        ? widget.theme.accent
        : widget.theme.buttonTop;
    final sideColor = widget.isActive
        ? widget.theme.accent.withOpacity(0.4)
        : widget.theme.buttonSide;

    Widget content;
    if (widget.isVertical && widget.icon != null) {
      // Claude Design 스타일 수직 버튼 (아이콘 위 + 라벨 아래) — 면의 정중앙에 배치
      final fg = widget.isActive
          ? widget.theme.deviceBg
          : widget.theme.textPrimary;
      final fg2 = widget.isActive
          ? widget.theme.deviceBg
          : widget.theme.textSecondary;
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 19, color: fg),
            const SizedBox(height: 3),
            // letterSpacing은 글자 뒤에 붙으므로, 같은 만큼 앞을 띄워 시각적 중앙을 맞춘다.
            Padding(
              padding: const EdgeInsets.only(left: 0.8),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg2,
                  fontSize: widget.fontSize,
                  fontFamily: 'SpaceMono',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Center(
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.isActive
                ? widget.theme.deviceBg
                : widget.theme.textPrimary,
            fontSize: widget.fontSize,
            fontFamily: 'SpaceMono',
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: widget.width,
        height: widget.height + _depth,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.theme.buttonBorder.withOpacity(0.6),
                    width: 1,
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: 0,
              right: 0,
              top: _pressed ? _depth : 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.theme.deviceBorder, topColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isActive
                        ? widget.theme.accent
                        : widget.theme.buttonBorder,
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: CustomPaint(painter: _ButtonScanlinePainter()),
                      ),
                    ),
                    content,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ★ 콘솔 A / B 둥근 버튼 (진단 선택·취소, 보드에서는 카드 이동·해제)
class RoundPadButton extends StatefulWidget {
  const RoundPadButton({
    super.key,
    required this.label,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final Color color;
  final MoodTheme theme;
  final VoidCallback onTap;

  @override
  State<RoundPadButton> createState() => _RoundPadButtonState();
}

class _RoundPadButtonState extends State<RoundPadButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final dark = Color.lerp(c, Colors.black, .45)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: '${widget.label} button',
          child: GestureDetector(
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) => setState(() => _down = false),
            onTapCancel: () => setState(() => _down = false),
            onTap: widget.onTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                width: 50,
                height: 50,
                transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-.24, -.36),
                    radius: .9,
                    colors: [Color.lerp(c, Colors.white, .25)!, c],
                  ),
                  boxShadow: [
                    BoxShadow(color: dark, offset: Offset(0, _down ? 1 : 5)),
                    if (!_down)
                      const BoxShadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 8),
                        blurRadius: 12,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 9,
            color: widget.theme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ★ 작은 알약 버튼 (SELECT/START 느낌) — 콘솔 메뉴 버튼
class PadPillButton extends StatefulWidget {
  const PadPillButton({
    super.key,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final MoodTheme theme;
  final VoidCallback onTap;

  @override
  State<PadPillButton> createState() => _PadPillButtonState();
}

class _PadPillButtonState extends State<PadPillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: widget.label,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) => setState(() => _down = false),
            onTapCancel: () => setState(() => _down = false),
            onTap: widget.onTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                width: 64,
                height: 18,
                transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
                decoration: BoxDecoration(
                  color: t.buttonTop,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: t.buttonSide, offset: Offset(0, _down ? 0 : 3)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 2,
            color: t.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ★ 버튼 표면용 미세 스캔라인 텍스처 (가벼운 레트로 질감)
class _ButtonScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.08);
    for (double y = 1; y < size.height; y += 2.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // 상단에 살짝 밝은 하이라이트 줄 (광택 느낌)
    final highlight = Paint()..color = Colors.white.withOpacity(0.10);
    canvas.drawLine(Offset(0, 1), Offset(size.width, 1), highlight);
  }

  @override
  bool shouldRepaint(covariant _ButtonScanlinePainter old) => false;
}

// ★ 3D D-PAD 버튼
class DPadButton3D extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final MoodTheme theme;
  final double size;

  const DPadButton3D({
    super.key,
    required this.icon,
    required this.onTap,
    required this.theme,
    this.size = 32.0,
  });

  @override
  State<DPadButton3D> createState() => _DPadButton3DState();
}

class _DPadButton3DState extends State<DPadButton3D> {
  bool _pressed = false;
  Timer? _repeatTimer;
  static const _depth = 4.0;

  void _startRepeating() {
    widget.onTap();
    _repeatTimer?.cancel();
    _repeatTimer = Timer(const Duration(milliseconds: 350), () {
      _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 80),
        (_) => widget.onTap(),
      );
    });
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _startRepeating();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _stopRepeating();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _stopRepeating();
      },
      child: SizedBox(
        width: s,
        height: s + _depth,
        child: Stack(
          children: [
            // 측면
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: widget.theme.buttonSide,
                  border: Border.all(
                    color: widget.theme.buttonBorder.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            // 표면 (Claude Design: shellHi→btnFace 그라디언트)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: 0,
              right: 0,
              top: _pressed ? _depth : 0,
              child: Container(
                height: s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.theme.deviceBorder, widget.theme.buttonBg],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.buttonSide,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: widget.theme.buttonBorder.withOpacity(0.7),
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.theme.textSecondary,
                  size: s * 0.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ★ 파티클 종류
// ★ HTML 원본과 동일한 파티클 타입
enum PType { star, dust, gold, glitch, bubble }

// ★ 무드별 파티클 설정 (HTML 원본과 동일)
class MoodParticleConfig {
  final PType ptype;
  final Color accent;
  final Color accent2;
  const MoodParticleConfig({
    required this.ptype,
    required this.accent,
    required this.accent2,
  });
}

// particleConfigs는 MoodTheme에서 직접 꺼냄 — 별도 map 불필요
// ptype 매핑
const moodPTypes = {
  'manifestation': PType.star,
  'soft_life': PType.dust,
  'that_girl': PType.gold,
  'cyber_dream': PType.glitch,
  'wanderlust': PType.bubble,
};

// ★ HTML 원본 Particle 구조 (픽셀 단위)
class HParticle {
  double x, y;
  double s; // star/gold: size, dust/bubble: radius
  double vy; // star/gold/bubble: vertical speed
  double vx; // dust: horizontal speed
  double ph; // phase
  double sp; // star/gold: twinkle speed
  double wob; // bubble: wobble
  double a; // bubble/dust: alpha
  double w, h, t; // glitch: width, height, ttl
  Color col; // glitch: color
  HParticle({
    this.x = 0,
    this.y = 0,
    this.s = 3,
    this.vy = 0.3,
    this.vx = 0,
    this.ph = 0,
    this.sp = 2,
    this.wob = 0.8,
    this.a = 0.2,
    this.w = 20,
    this.h = 2,
    this.t = 20,
    this.col = const Color(0xFFFFFFFF),
  });
}

// ★ 화면 전체 떠다니는 파티클 레이어 (HTML 원본 로직)
class ParticleOverlay extends StatefulWidget {
  final String mood;
  final Color accent;
  final Color accent2;
  const ParticleOverlay({
    super.key,
    required this.mood,
    required this.accent,
    required this.accent2,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  List<HParticle> _particles = [];
  String _builtForMood = '';
  double _w = 0, _h = 0;

  @override
  void initState() {
    super.initState();
    // HTML 원본: requestAnimationFrame 루프 → 60fps로 맞춤
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _buildParticles(800, 500);
  }

  @override
  void didUpdateWidget(covariant ParticleOverlay old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _buildParticles(_w, _h);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _R(double a, double b) {
    final rng = Random();
    return a + rng.nextDouble() * (b - a);
  }

  void _buildParticles(double w, double h) {
    _w = w;
    _h = h;
    final ptype = moodPTypes[widget.mood] ?? PType.star;
    final List<HParticle> items = [];
    int n;
    switch (ptype) {
      case PType.star:
        n = 72;
        break;
      case PType.dust:
        n = 46;
        break;
      case PType.gold:
        n = 30;
        break;
      case PType.glitch:
        n = 58;
        break;
      case PType.bubble:
        n = 34;
        break;
    }
    for (int i = 0; i < n; i++) {
      switch (ptype) {
        case PType.star:
        case PType.gold:
          items.add(
            HParticle(
              x: _R(0, w),
              y: _R(0, h),
              s: _R(2, 7),
              vy: _R(.15, .6),
              ph: _R(0, 6.28),
              sp: _R(1.2, 3),
            ),
          );
          break;
        case PType.dust:
          items.add(
            HParticle(
              x: _R(0, w),
              y: _R(0, h),
              s: _R(8, 26),
              vx: _R(-.18, .18),
              vy: _R(-.14, .14),
              a: _R(.05, .16),
              ph: _R(0, 6.28),
            ),
          );
          break;
        case PType.glitch:
          items.add(
            HParticle(
              x: _R(0, w),
              y: _R(0, h),
              w: _R(3, 46),
              h: _R(1, 3),
              t: _R(6, 46),
              col: Random().nextDouble() < .5 ? widget.accent : widget.accent2,
            ),
          );
          break;
        case PType.bubble:
          items.add(
            HParticle(
              x: _R(0, w),
              y: _R(0, h),
              s: _R(4, 16),
              vy: _R(.25, .7),
              wob: _R(.4, 1.2),
              ph: _R(0, 6.28),
              a: _R(.1, .3),
            ),
          );
          break;
      }
    }
    _particles = items;
    _builtForMood = widget.mood;
  }

  @override
  Widget build(BuildContext context) {
    if (_builtForMood != widget.mood) _buildParticles(_w, _h);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
            if (_w != constraints.maxWidth || _h != constraints.maxHeight) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted)
                  _buildParticles(constraints.maxWidth, constraints.maxHeight);
              });
            }
          }
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              painter: HParticlePainter(
                particles: _particles,
                ptype: moodPTypes[widget.mood] ?? PType.star,
                accent: widget.accent,
                accent2: widget.accent2,
                w: constraints.maxWidth,
                h: constraints.maxHeight,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

// ★ HTML 원본 drawParticles 로직을 그대로 포팅
class HParticlePainter extends CustomPainter {
  final List<HParticle> particles;
  final PType ptype;
  final Color accent, accent2;
  final double w, h;

  HParticlePainter({
    required this.particles,
    required this.ptype,
    required this.accent,
    required this.accent2,
    required this.w,
    required this.h,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = 1.0; // 프레임당 픽셀 이동량 (HTML 원본: rAF 60fps 기준)

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];

      if (ptype == PType.star || ptype == PType.gold) {
        // HTML: p.y -= p.vy; if(p.y < -12){ p.y = h+12; p.x = random*w; }
        p.y -= p.vy * dt;
        if (p.y < -12) {
          p.y = h + 12;
          p.x = Random().nextDouble() * w;
        }

        final al = (.3 + .7 * (sin(time * p.sp + p.ph)).abs()).clamp(0.0, 1.0);

        Color fillColor;
        if (ptype == PType.gold) {
          fillColor = accent;
        } else {
          fillColor = (i % 5 == 0)
              ? accent2
              : (i % 2 == 1 ? accent : Colors.white);
        }

        canvas.save();
        final r = p.s;
        final x = p.x;
        final y = p.y;
        // 글로우
        canvas.drawCircle(
          Offset(x, y),
          r * 2,
          Paint()
            ..color = fillColor.withOpacity(al * 0.3)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.5),
        );
        // 8각별
        final path = Path();
        path.moveTo(x, y - r);
        path.lineTo(x + r * .26, y - r * .26);
        path.lineTo(x + r, y);
        path.lineTo(x + r * .26, y + r * .26);
        path.lineTo(x, y + r);
        path.lineTo(x - r * .26, y + r * .26);
        path.lineTo(x - r, y);
        path.lineTo(x - r * .26, y - r * .26);
        path.close();
        canvas.drawPath(path, Paint()..color = fillColor.withOpacity(al));
        canvas.restore();
      } else if (ptype == PType.dust) {
        // HTML: p.x += p.vx; p.y += p.vy; wrap around
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        if (p.x < -30) p.x = w + 30;
        if (p.x > w + 30) p.x = -30;
        if (p.y < -30) p.y = h + 30;
        if (p.y > h + 30) p.y = -30;

        final al = p.a * (.6 + .4 * sin(time * .5 + p.ph));
        final fillColor = i % 2 == 1 ? accent2 : accent;
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.s,
          Paint()..color = fillColor.withOpacity(al.clamp(0.0, 1.0)),
        );
      } else if (ptype == PType.glitch) {
        // HTML: p.t -= 1; if(p.t<=0) regenerate
        p.t -= dt;
        if (p.t <= 0) {
          p.x = Random().nextDouble() * w;
          p.y = Random().nextDouble() * h;
          p.w = 3 + Random().nextDouble() * 46;
          p.h = 1 + Random().nextDouble() * 3;
          p.t = 6 + Random().nextDouble() * 46;
          p.col = Random().nextDouble() < .5 ? accent : accent2;
        }
        canvas.drawRect(
          Rect.fromLTWH(p.x, p.y, p.w, p.h),
          Paint()..color = p.col.withOpacity(0.55),
        );
      } else {
        // bubble
        // HTML: p.y -= p.vy; p.x += sin(time*p.wob+p.ph)*0.5;
        p.y -= p.vy * dt;
        p.x += sin(time * p.wob + p.ph) * 0.5;
        if (p.y < -p.s) {
          p.y = h + p.s;
          p.x = Random().nextDouble() * w;
        }

        canvas.drawCircle(
          Offset(p.x, p.y),
          p.s,
          Paint()
            ..color = accent.withOpacity(p.a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
        // 하이라이트 (HTML: accent2 dot)
        canvas.drawCircle(
          Offset(p.x - p.s * .3, p.y - p.s * .3),
          p.s * .18,
          Paint()..color = accent2.withOpacity((p.a * 1.4).clamp(0.0, 1.0)),
        );
      }
    }
    canvas.drawColor(Colors.transparent, BlendMode.dstOver);
  }

  @override
  bool shouldRepaint(covariant HParticlePainter old) => true;
}

// particleConfigs는 LED 색상용으로만 유지
const particleConfigs = {
  'manifestation': _PInfo(color: Color(0xFFcf8bff)),
  'soft_life': _PInfo(color: Color(0xFFb06a44)),
  'that_girl': _PInfo(color: Color(0xFFcba24f)),
  'cyber_dream': _PInfo(color: Color(0xFF2fe6ff)),
  'wanderlust': _PInfo(color: Color(0xFF52d6c8)),
};

class _PInfo {
  final Color color;
  const _PInfo({required this.color});
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
  int? draggingIndex; // ★ 드래그 중인 카드 (들어올리기 효과용)
  int? spawnIndex; // ★ 방금 추가된 카드 (뱉어내는 등장 효과용)
  bool isLoading = true;
  bool _animStarted = false;
  bool _isExporting = false;
  String _currentMood = 'manifestation';

  // ★ DREAM OS 진단 (심리테스트) 상태
  bool _showQuiz = false;
  String? _myResultMood; // 저장된 내 진단 결과 (궁합 계산용)
  final _diagController = DiagnosisController();

  // ★ 공유 보드 뷰 상태
  bool _isSharedView = false;
  String? _sharedResultMood; // 공유한 사람의 진단 결과

  // 번들에 실제로 포함된 에셋 경로. 없는 이미지는 요청하지 않고 바로 타일로 그린다(404 방지).
  Set<String> _assetKeys = const {};
  bool _hasAsset(String? path) => path != null && _assetKeys.contains(path);

  // ★ 사운드는 인트로와 공유하는 WebSynth를 쓴다 (lib/web_synth.dart)
  bool get _soundOn => WebSynth.instance.enabled;

  final GlobalKey _boardKey = GlobalKey();
  late AnimationController _introController;
  late AnimationController _floatController;
  late AnimationController _neonController;
  late AnimationController _spotlightController; // ★ 스포트라이트 애니메이션
  late AnimationController _selectScaleController; // ★ 선택 카드 확대 애니메이션
  late AnimationController
  _moodTransitionController; // ★ 무드 전환 트랜지션 (카트리지 교체 느낌)
  late AnimationController _spawnController; // ★ 새 카드 뱉어내는 등장 애니메이션
  late AnimationController _savePulseController; // ★ 저장 시 화면 펄스 효과
  final List<double> _floatOffsets = [];
  static const _stickerCurve = _StickerCurve();

  MoodTheme get _theme =>
      moodThemes[_currentMood] ?? moodThemes['manifestation']!;

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
    'imgs/Manifestation/manifestation_01.jpg',
    'imgs/Manifestation/manifestation_02.jpg',
    'imgs/Manifestation/manifestation_03.jpg',
    'imgs/Manifestation/manifestation_04.jpg',
    'imgs/Manifestation/manifestation_05.jpg',
    'imgs/Manifestation/manifestation_06.jpg',
    'imgs/Manifestation/manifestation_07.jpg',
    'imgs/Manifestation/manifestation_08.jpg',
    'imgs/Manifestation/manifestation_09.jpg',
    'imgs/Manifestation/manifestation_10.jpg',
    'imgs/Manifestation/manifestation_11.jpg',
    'imgs/Manifestation/manifestation_12.jpg',
    'imgs/Manifestation/manifestation_13.jpg',
    'imgs/Manifestation/manifestation_14.jpg',
    'imgs/Manifestation/manifestation_15.jpg',
    'imgs/Manifestation/manifestation_16.jpg',
    'imgs/Manifestation/manifestation_17.jpg',
    'imgs/Manifestation/manifestation_18.jpg',
    'imgs/Manifestation/manifestation_19.jpg',
    'imgs/Manifestation/manifestation_20.jpg',
    'imgs/Manifestation/manifestation_21.jpg',
    'imgs/Manifestation/manifestation_22.jpg',
    'imgs/Manifestation/manifestation_23.jpg',
    'imgs/Manifestation/manifestation_24.jpg',
    'imgs/Manifestation/manifestation_25.jpg',
    'imgs/Manifestation/manifestation_26.jpg',
    'imgs/Manifestation/manifestation_27.jpg',
    'imgs/Manifestation/manifestation_28.jpg',
    'imgs/Manifestation/manifestation_29.jpg',
    'imgs/Manifestation/manifestation_30.jpg',
    'imgs/Manifestation/manifestation_31.jpg',
    'imgs/Manifestation/manifestation_32.jpg',
    'imgs/Manifestation/manifestation_33.jpg',
    'imgs/Manifestation/manifestation_34.jpg',
    'imgs/Manifestation/manifestation_35.png',
  ];

  static const moodImages = {
    'soft_life': [
      'imgs/soft_life/soft_life_01.jpg',
      'imgs/soft_life/soft_life_02.jpg',
      'imgs/soft_life/soft_life_03.jpg',
      'imgs/soft_life/soft_life_04.jpg',
      'imgs/soft_life/soft_life_05.jpg',
      'imgs/soft_life/soft_life_06.jpg',
      'imgs/soft_life/soft_life_07.jpg',
      'imgs/soft_life/soft_life_08.jpg',
      'imgs/soft_life/soft_life_09.jpg',
      'imgs/soft_life/soft_life_10.jpg',
      'imgs/soft_life/soft_life_11.jpg',
      'imgs/soft_life/soft_life_12.jpg',
      'imgs/soft_life/soft_life_13.jpg',
      'imgs/soft_life/soft_life_14.jpg',
      'imgs/soft_life/soft_life_15.jpg',
      'imgs/soft_life/soft_life_16.jpg',
      'imgs/soft_life/soft_life_17.jpg',
      'imgs/soft_life/soft_life_18.jpg',
      'imgs/soft_life/soft_life_19.jpg',
      'imgs/soft_life/soft_life_20.png',
    ],
    'that_girl': [
      'imgs/That_Girl/that_girl_01.jpg',
      'imgs/That_Girl/that_girl_02.jpg',
      'imgs/That_Girl/that_girl_03.jpg',
      'imgs/That_Girl/that_girl_04.jpg',
      'imgs/That_Girl/that_girl_05.jpg',
      'imgs/That_Girl/that_girl_06.jpg',
      'imgs/That_Girl/that_girl_07.jpg',
      'imgs/That_Girl/that_girl_08.jpg',
      'imgs/That_Girl/that_girl_09.jpg',
      'imgs/That_Girl/that_girl_10.jpg',
      'imgs/That_Girl/that_girl_11.jpg',
      'imgs/That_Girl/that_girl_12.jpg',
      'imgs/That_Girl/that_girl_13.jpg',
      'imgs/That_Girl/that_girl_14.jpg',
      'imgs/That_Girl/that_girl_15.jpg',
      'imgs/That_Girl/that_girl_16.jpg',
      'imgs/That_Girl/that_girl_17.jpg',
      'imgs/That_Girl/that_girl_18.jpg',
      'imgs/That_Girl/that_girl_19.jpg',
      'imgs/That_Girl/that_girl_20.jpg',
      'imgs/That_Girl/that_girl_21.jpg',
      'imgs/That_Girl/that_girl_22.jpg',
      'imgs/That_Girl/that_girl_23.png',
    ],
    'cyber_dream': [
      'imgs/Cyber_Dream/cyber_dream_01.jpg',
      'imgs/Cyber_Dream/cyber_dream_02.jpg',
      'imgs/Cyber_Dream/cyber_dream_03.jpg',
      'imgs/Cyber_Dream/cyber_dream_04.jpg',
      'imgs/Cyber_Dream/cyber_dream_05.jpg',
      'imgs/Cyber_Dream/cyber_dream_06.jpg',
      'imgs/Cyber_Dream/cyber_dream_07.jpg',
      'imgs/Cyber_Dream/cyber_dream_08.jpg',
      'imgs/Cyber_Dream/cyber_dream_09.jpg',
      'imgs/Cyber_Dream/cyber_dream_10.jpg',
      'imgs/Cyber_Dream/cyber_dream_11.jpg',
      'imgs/Cyber_Dream/cyber_dream_12.jpg',
      'imgs/Cyber_Dream/cyber_dream_13.jpg',
      'imgs/Cyber_Dream/cyber_dream_14.jpg',
      'imgs/Cyber_Dream/cyber_dream_15.jpg',
      'imgs/Cyber_Dream/cyber_dream_16.jpg',
      'imgs/Cyber_Dream/cyber_dream_17.jpg',
      'imgs/Cyber_Dream/cyber_dream_18.jpg',
    ],
    'wanderlust': [
      'imgs/wanderlust/wanderlust_01.jpg',
      'imgs/wanderlust/wanderlust_02.jpg',
      'imgs/wanderlust/wanderlust_03.jpg',
      'imgs/wanderlust/wanderlust_04.jpg',
      'imgs/wanderlust/wanderlust_05.jpg',
      'imgs/wanderlust/wanderlust_06.jpg',
      'imgs/wanderlust/wanderlust_07.jpg',
      'imgs/wanderlust/wanderlust_08.jpg',
      'imgs/wanderlust/wanderlust_09.jpg',
      'imgs/wanderlust/wanderlust_10.jpg',
      'imgs/wanderlust/wanderlust_11.jpg',
      'imgs/wanderlust/wanderlust_12.jpg',
      'imgs/wanderlust/wanderlust_13.jpg',
      'imgs/wanderlust/wanderlust_14.jpg',
      'imgs/wanderlust/wanderlust_15.jpg',
      'imgs/wanderlust/wanderlust_16.jpg',
      'imgs/wanderlust/wanderlust_17.jpg',
      'imgs/wanderlust/wanderlust_18.jpg',
      'imgs/wanderlust/wanderlust_19.jpg',
      'imgs/wanderlust/wanderlust_20.jpg',
      'imgs/wanderlust/wanderlust_21.jpg',
      'imgs/wanderlust/wanderlust_22.jpg',
      'imgs/wanderlust/wanderlust_23.jpg',
      'imgs/wanderlust/wanderlust_24.jpg',
      'imgs/wanderlust/wanderlust_25.jpg',
      'imgs/wanderlust/wanderlust_26.jpg',
      'imgs/wanderlust/wanderlust_27.jpg',
      'imgs/wanderlust/wanderlust_28.jpg',
      'imgs/wanderlust/wanderlust_29.jpg',
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
    // Claude Design 팔레트 기반 — radial gradient 스타일
    'manifestation': BoardBackground(
      type: BgType.gradient,
      color1: 0xFF271447,
      color2: 0xFF0c0718,
      color3: 0xFF150a30,
      useColor3: true,
    ),
    'soft_life': BoardBackground(
      type: BgType.gradient,
      color1: 0xFFcdb796,
      color2: 0xFF8f7a5c,
      color3: 0xFFead7b8,
      useColor3: true,
    ),
    'that_girl': BoardBackground(
      type: BgType.gradient,
      color1: 0xFF1a1814,
      color2: 0xFF050504,
      color3: 0xFF100e0b,
      useColor3: true,
    ),
    'cyber_dream': BoardBackground(
      type: BgType.gradient,
      color1: 0xFF0c1a3a,
      color2: 0xFF02040d,
      color3: 0xFF061336,
      useColor3: true,
    ),
    'wanderlust': BoardBackground(
      type: BgType.gradient,
      color1: 0xFF103440,
      color2: 0xFF04161d,
      color3: 0xFF134552,
      useColor3: true,
    ),
  };

  static const moodBgImages = {
    'manifestation': [
      'background/Manifestation/bg_manifestation_01.jpg',
      'background/Manifestation/bg_manifestation_02.png',
    ],
    'soft_life': [
      'background/soft_life/bg_soft_life_01.jpg',
      'background/soft_life/bg_soft_life_02.jpg',
      'background/soft_life/bg_soft_life_03.jpg',
      'background/soft_life/bg_soft_life_04.jpg',
      'background/soft_life/bg_soft_life_05.jpg',
    ],
    'that_girl': [
      'background/That_Girl/bg_that_girl_01.jpg',
      'background/That_Girl/bg_that_girl_02.jpg',
      'background/That_Girl/bg_that_girl_03.jpg',
      'background/That_Girl/bg_that_girl_04.jpg',
    ],
    'cyber_dream': [
      'background/Cyber_Dream/bg_cyber_dream_01.jpg',
      'background/Cyber_Dream/bg_cyber_dream_02.jpg',
      'background/Cyber_Dream/bg_cyber_dream_03.jpg',
      'background/Cyber_Dream/bg_cyber_dream_04.jpg',
      'background/Cyber_Dream/bg_cyber_dream_05.jpg',
      'background/Cyber_Dream/bg_cyber_dream_06.jpg',
      'background/Cyber_Dream/bg_cyber_dream_07.png',
    ],
    'wanderlust': [
      'background/wanderlust/bg_wanderlust_01.jpg',
      'background/wanderlust/bg_wanderlust_02.jpg',
      'background/wanderlust/bg_wanderlust_03.jpg',
      'background/wanderlust/bg_wanderlust_04.jpg',
      'background/wanderlust/bg_wanderlust_05.jpg',
      'background/wanderlust/bg_wanderlust_06.jpg',
    ],
  };

  static const moodLabels = {
    'manifestation': '✨ MNFST',
    'soft_life': '🌿 SOFT',
    'that_girl': '💪 GIRL',
    'cyber_dream': '🌀 CYBER',
    'wanderlust': '🌍 WNDRL',
  };

  Future<void> _onLangChanged() async {
    if (mounted) setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', appLang.value);
  }

  @override
  void initState() {
    super.initState();
    appLang.addListener(_onLangChanged);
    AssetManifest.loadFromAssetBundle(rootBundle).then((m) {
      if (mounted) setState(() => _assetKeys = m.listAssets().toSet());
    });
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
    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _selectScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _moodTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _spawnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _savePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadBoard();
  }

  @override
  void dispose() {
    appLang.removeListener(_onLangChanged);
    _introController.dispose();
    _floatController.dispose();
    _neonController.dispose();
    _spotlightController.dispose();
    _selectScaleController.dispose();
    _moodTransitionController.dispose();
    _spawnController.dispose();
    _savePulseController.dispose();
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

  void _selectCard(int? index) {
    setState(() => selectedIndex = index);
    if (index != null) {
      _pickBlip(true);
      _spotlightController.forward(from: 0);
      _selectScaleController.forward(from: 0);
    } else {
      _spotlightController.reverse();
      _selectScaleController.reverse();
    }
  }

  // ★ 새 카드 추가 시 "뱉어내는" 등장 애니메이션 트리거
  void _triggerSpawnAnimation(int index) {
    setState(() => spawnIndex = index);
    _spawnController.forward(from: 0).then((_) {
      if (mounted) setState(() => spawnIndex = null);
    });
  }

  // ★ D-PAD로 카드 이동
  void _moveSelectedCard(double dx, double dy) {
    if (_showQuiz) {
      _diagController.press(
        dx < 0
            ? DiagKey.left
            : dx > 0
            ? DiagKey.right
            : dy < 0
            ? DiagKey.up
            : DiagKey.down,
      );
      return;
    }
    if (selectedIndex == null || selectedIndex! >= cards.length) return;
    _dpadBlip();
    setState(() {
      final card = cards[selectedIndex!];
      card.xRatio = (card.xRatio + dx).clamp(0.0, 1.0);
      card.yRatio = (card.yRatio + dy).clamp(0.0, 1.0);
    });
    _scheduleSave();
  }

  Timer? _saveDebounce;
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _saveBoard);
  }

  Future<void> _loadBoard() async {
    final prefs = await SharedPreferences.getInstance();
    _myResultMood = prefs.getString('quiz_result');
    final savedLang = prefs.getString('lang');
    if (savedLang == 'en' || savedLang == 'ko') appLang.value = savedLang!;

    // ★ 공유 링크(#b=)로 들어온 경우 — 공유된 보드를 우선 표시
    if (_loadFromHash()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _startIntroAnimation();
        });
      });
      return;
    }

    final savedBg = prefs.getString('board_background');
    if (savedBg != null)
      background = BoardBackground.fromJson(jsonDecode(savedBg));
    // ★ 무드(콘솔 스킨)도 보드와 함께 복원
    final savedMood = prefs.getString('current_mood');
    if (savedMood != null && moodThemes.containsKey(savedMood))
      _currentMood = savedMood;
    final saved = prefs.getString('board_cards');
    if (saved != null) {
      final List<dynamic> jsonList = jsonDecode(saved);
      setState(() {
        cards = jsonList.map((e) => BoardCard.fromJson(e)).toList();
        isLoading = false;
      });
      _initFloatOffsets();
      _updateFloatSpeed();
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
    // 공유 링크 열람 중에는 방문자의 보드를 덮어쓰지 않음
    if (_isSharedView) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'board_cards',
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
    await prefs.setString('board_background', jsonEncode(background.toJson()));
    await prefs.setString('current_mood', _currentMood);
  }

  Future<void> _exportAsPng() async {
    setState(() => _isExporting = true);
    try {
      _selectCard(null);
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
          SnackBar(
            content: Text('Saved! 🎨', style: TextStyle(color: _theme.accent)),
            duration: const Duration(seconds: 2),
            backgroundColor: _theme.deviceBg,
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

  // ─────────────────────────────────────────────
  // ★ 사운드 — 공용 WebSynth로 위임 (브라우저 autoplay 정책상 첫 클릭 후부터 소리남)
  // ─────────────────────────────────────────────
  void _buttonBlip() => WebSynth.instance.buttonBlip();
  void _dpadBlip() => WebSynth.instance.dpadBlip();
  void _pickBlip(bool on) => WebSynth.instance.pickBlip(on);
  void _moodChime(String key) => WebSynth.instance.moodChime(key);

  // ─────────────────────────────────────────────
  // ★ 스토리 export — 보드 캡처를 1080×1920 세로 프레임에 합성
  // 인스타 스토리 공유용
  // ─────────────────────────────────────────────
  Future<void> _exportStory() async {
    setState(() => _isExporting = true);
    try {
      _selectCard(null);
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary =
          _boardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final board = await boundary.toImage(pixelRatio: 2.0);

      const w = 1080.0, h = 1920.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));
      final t = _theme;

      // 무드 그라디언트 배경
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = ui.Gradient.linear(const Offset(w / 2, 0), const Offset(
            w / 2,
            h,
          ), [t.deviceBorder, t.deviceBg, t.deviceBg2], [0.0, 0.2, 1.0]),
      );

      double drawCenteredText(
        String text,
        double y, {
        double size = 32,
        Color? color,
        FontWeight weight = FontWeight.bold,
        double letterSpacing = 3,
        List<Shadow>? shadows,
        String fam = 'SpaceMono',
      }) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color ?? t.textPrimary,
              fontSize: size,
              fontFamily: fam,
              fontWeight: weight,
              letterSpacing: letterSpacing,
              height: 1.5,
              shadows: shadows,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: w - 100);
        tp.paint(canvas, Offset((w - tp.width) / 2, y));
        return y + tp.height;
      }

      // 헤더
      drawCenteredText(
        '— MOODCOLLAGE • DREAM OS —',
        130,
        size: 20,
        color: t.textSecondary,
        weight: FontWeight.normal,
      );
      drawCenteredText(
        'VISION BOARD',
        170,
        size: 52,
        color: t.accent,
        letterSpacing: 6,
        fam: 'PressStart2P',
        shadows: [Shadow(color: t.glowColor, blurRadius: 40)],
      );

      // 보드 이미지 (라운드 클립 + 글로우 프레임)
      const imgW = 960.0;
      final imgH = (imgW * board.height / board.width).clamp(200.0, 1150.0);
      final dst = Rect.fromLTWH((w - imgW) / 2, 340, imgW, imgH);
      final rrect = RRect.fromRectAndRadius(dst, const Radius.circular(24));
      canvas.drawRRect(
        rrect.inflate(6),
        Paint()
          ..color = t.glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
      );
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawImageRect(
        board,
        Rect.fromLTWH(0, 0, board.width.toDouble(), board.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = t.accent,
      );

      // 무드 결과 텍스트
      final dm = diagMoods[_currentMood];
      double y = dst.bottom + 70;
      if (dm != null) {
        y = drawCenteredText(
          tr('나의 OS', 'MY OS'),
          y,
          size: 24,
          color: t.textSecondary,
          weight: FontWeight.normal,
          letterSpacing: 4,
          fam: 'Jua',
        );
        y = drawCenteredText(
          '${dm.emoji}  ${dm.title}',
          y + 10,
          size: 56,
          color: t.accent,
          letterSpacing: 2,
          shadows: [Shadow(color: t.glowColor, blurRadius: 30)],
          fam: 'Jua',
        );
        drawCenteredText(
          dm.desc,
          y + 16,
          size: 28,
          weight: FontWeight.normal,
          letterSpacing: 0,
          fam: 'Jua',
        );
      }

      // 푸터 — 앱 링크
      final loc = html.window.location;
      drawCenteredText(
        '${loc.host}${loc.pathname}',
        h - 130,
        size: 20,
        color: t.textSecondary,
        weight: FontWeight.normal,
        letterSpacing: 2,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(w.toInt(), h.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      _downloadBytes(
        byteData.buffer.asUint8List(),
        'vision_board_story.png',
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Story saved! 📲 1080×1920',
              style: TextStyle(color: _theme.accent),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _theme.deviceBg,
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

  // ─────────────────────────────────────────────
  // ★ DREAM OS 진단 — lib/diagnosis.dart 의 DiagnosisScreen을 연결한다.
  // ─────────────────────────────────────────────

  void _startQuiz() {
    _selectCard(null);
    setState(() => _showQuiz = true);
  }

  Future<void> _onDiagResult(String mood, Map<String, int> scores) async {
    WebSynth.instance.moodChime(mood);
    setState(() => _myResultMood = mood);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quiz_result', mood);
    await prefs.setString('quiz_scores', jsonEncode(scores));
    await prefs.setBool('quiz_done', true);
  }

  void _onDiagBuild(String mood) {
    setState(() => _showQuiz = false);
    _applyMood(mood, force: true);
  }

  Future<void> _onDiagClose() async {
    setState(() => _showQuiz = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quiz_done', true);
  }

  DiagPalette _diagPalette(String mood) {
    final t = moodThemes[mood] ?? _theme;
    // 진단 화면은 어두운 바탕 위에서 보이므로, 밝은 테마(SOFT)에서도 읽히도록
    // 테마의 글자색 대신 항상 밝은 글자색을 쓰고 무드 색은 살짝만 섞는다.
    return DiagPalette(
      accent: Color.lerp(t.accent, Colors.white, .12)!,
      accent2: t.accent2,
      text: Color.lerp(Colors.white, t.accent, .1)!,
      muted: Color.lerp(Colors.white, t.accent, .4)!.withOpacity(.72),
      bg: Color.lerp(const Color(0xFF0B0814), t.accent, .14)!,
      glow: t.glowColor,
    );
  }

  // 콘솔 A / B — 진단 중엔 진단 조작, 보드에서는 카드 선택 이동 / 해제
  void _consoleA() {
    if (_showQuiz) {
      _diagController.press(DiagKey.a);
      return;
    }
    if (cards.isEmpty) return;
    _selectCard(((selectedIndex ?? -1) + 1) % cards.length);
  }

  void _consoleB() {
    if (_showQuiz) {
      _diagController.press(DiagKey.b);
      return;
    }
    _selectCard(null);
  }

  // ─────────────────────────────────────────────
  // ★ 공유 링크 — 보드 상태를 URL 해시(#b=)에 직렬화
  // 업로드한 base64 이미지는 제외 (URL 길이 제한)
  // ─────────────────────────────────────────────

  double _r4(double v) => (v * 10000).roundToDouble() / 10000;

  String _encodeBoard() {
    final payload = {
      'v': 1,
      'm': _currentMood,
      if (_myResultMood != null) 'r': _myResultMood,
      'bg': background.toJson()..remove('imageBase64'),
      'c': [
        for (final c in cards)
          if (c.imageBase64 == null)
            {
              if (c.imageUrl != null) 'u': c.imageUrl,
              if (c.text != null) 't': c.text,
              'x': _r4(c.xRatio),
              'y': _r4(c.yRatio),
              'w': _r4(c.widthRatio),
              'h': _r4(c.heightRatio),
              'o': _r4(c.rotation),
              's': c.style.index,
              'p': c.paperColor,
              'k': c.textColor,
            },
      ],
    };
    return base64UrlEncode(utf8.encode(jsonEncode(payload)));
  }

  bool _loadFromHash() {
    final live = html.window.location.hash;
    final hash = live.startsWith('#b=') ? live : initialUrlHash;
    if (!hash.startsWith('#b=')) return false;
    try {
      final raw = utf8.decode(
        base64Url.decode(base64Url.normalize(hash.substring(3))),
      );
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final mood = payload['m'] as String?;
      if (mood == null || !moodThemes.containsKey(mood)) return false;
      final loaded = <BoardCard>[];
      for (final c in (payload['c'] as List? ?? [])) {
        final si = (c['s'] ?? 0) as int;
        loaded.add(
          BoardCard(
            imageUrl: c['u'],
            text: c['t'],
            xRatio: (c['x'] ?? 0.1).toDouble(),
            yRatio: (c['y'] ?? 0.1).toDouble(),
            widthRatio: (c['w'] ?? 0.12).toDouble(),
            heightRatio: (c['h'] ?? 0.12).toDouble(),
            rotation: (c['o'] ?? 0).toDouble(),
            style: si < CardStyle.values.length
                ? CardStyle.values[si]
                : CardStyle.torn,
            paperColor: c['p'] ?? 0xFFF5F0E8,
            textColor: c['k'] ?? 0xFF1a1a1a,
          ),
        );
      }
      if (loaded.isEmpty) return false;
      final bgJson = payload['bg'];
      setState(() {
        _currentMood = mood;
        _sharedResultMood = payload['r'];
        _isSharedView = true;
        cards = loaded;
        if (bgJson is Map<String, dynamic>)
          background = BoardBackground.fromJson(bgJson);
        isLoading = false;
      });
      _initFloatOffsets();
      _updateFloatSpeed();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _shareBoard() async {
    final loc = html.window.location;
    final link = '${loc.origin}${loc.pathname}#b=${_encodeBoard()}';
    try {
      await html.window.navigator.clipboard?.writeText(link);
      _savePulseController.forward(from: 0);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'LINK COPIED 🔗 send it to a friend',
              style: TextStyle(color: _theme.accent, fontFamily: 'SpaceMono'),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _theme.screenBorder,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clipboard error: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // 공유 뷰에서 "나도 만들기" — 해시 제거 후 내 진단 시작
  void _exitSharedView() {
    final loc = html.window.location;
    html.window.history.replaceState(null, '', '${loc.pathname}${loc.search}');
    setState(() {
      _isSharedView = false;
      _sharedResultMood = null;
    });
    _startQuiz();
  }

  void _applyMood(String moodKey, {bool force = false}) {
    if (moodKey == _currentMood && !force) return;
    _moodChime(moodKey);
    final rng = Random(DateTime.now().millisecondsSinceEpoch);
    final newCards = _buildMoodCards(moodKey, rng);

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

    _selectCard(null);

    // ★ 카트리지 교체 트랜지션
    // 1. 암전 (350ms) → 2. 콘텐츠 교체 → 3. 밝아짐 (350ms) → 4. 인트로 애니메이션
    _moodTransitionController.duration = const Duration(milliseconds: 350);
    _moodTransitionController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        cards = newCards;
        background = newBg;
        _animStarted = false;
        _currentMood = moodKey;
      });
      _initFloatOffsets();
      _updateFloatSpeed();
      _saveBoard();
      _moodTransitionController.duration = const Duration(milliseconds: 500);
      _moodTransitionController.reverse();
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _startIntroAnimation();
      });
    });
  }

  void _generateDefaultBoard() {
    final newCards = _buildMoodCards('manifestation', Random(56));
    setState(() => cards = newCards);
    _saveBoard();
  }

  // 보드의 실제 크기 (보드 화면 LayoutBuilder가 갱신)
  double _boardW = 0, _boardH = 0;

  /// 여유롭고 큼직한 배치: 보드를 칸으로 나누고 칸마다 카드 하나를 약간 흔들어 놓는다.
  /// 가로 4×3, 정사각에 가까우면 3×3, 세로(휴대폰) 2×4. 문구는 약 1/3.
  List<BoardCard> _buildMoodCards(String moodKey, Random rng) {
    final mq = MediaQuery.of(context).size;
    final bw = _boardW > 0 ? _boardW : max(320.0, mq.width - 440);
    final bh = _boardH > 0 ? _boardH : max(300.0, mq.height - 200);
    final aspect = bw / bh;
    final int cols, rows;
    if (aspect >= 1.25) {
      cols = 4;
      rows = 3;
    } else if (aspect >= 0.8) {
      cols = 3;
      rows = 3;
    } else {
      cols = 2;
      rows = 4;
    }
    final slots = cols * rows;
    final nText = (slots / 3).round();
    final textSlots = (List.generate(slots, (i) => i)..shuffle(rng))
        .take(nText)
        .toSet();
    final images = [
      ...(moodKey == 'manifestation'
          ? defaultImages
          : (moodImages[moodKey] ?? defaultImages)),
    ]..shuffle(rng);
    final texts = [...moodTextSets[moodKey]!]..shuffle(rng);

    final cellW = bw / cols, cellH = bh / rows;
    final out = <BoardCard>[];
    var pi = 0, ti = 0;
    for (var slot = 0; slot < slots; slot++) {
      final col = slot % cols, row = slot ~/ cols;
      final cx = (col + .5) * cellW + (rng.nextDouble() - .5) * cellW * .16;
      final cy = (row + .5) * cellH + (rng.nextDouble() - .5) * cellH * .16;
      if (textSlots.contains(slot)) {
        final (text, style, paper, color) = texts[ti++ % texts.length];
        final wPx = cellW * .62;
        final hPx = min(cellH * .42, wPx * .45);
        out.add(
          BoardCard(
            text: text,
            xRatio: ((cx - wPx / 2) / bw).clamp(.01, .99 - wPx / bw),
            yRatio: ((cy - hPx / 2) / bh).clamp(.01, .99 - hPx / bh),
            widthRatio: wPx / bw,
            heightRatio: hPx / bw,
            rotation: (rng.nextDouble() - .5) * .2,
            style: style,
            paperColor: paper,
            textColor: color,
          ),
        );
      } else {
        final asp = .9 + rng.nextDouble() * .25; // 사진 높이 / 너비
        final wPx = min(cellW * .8, (cellH * .9 - 24) / asp);
        final hPx = wPx * asp;
        out.add(
          BoardCard(
            imageUrl: images[pi++ % images.length],
            xRatio: ((cx - wPx / 2) / bw).clamp(.01, .99 - wPx / bw),
            yRatio: ((cy - (hPx + 24) / 2) / bh).clamp(.01, .99 - (hPx + 24) / bh),
            widthRatio: wPx / bw,
            heightRatio: hPx / bw,
            rotation: (rng.nextDouble() - .5) * .16,
          ),
        );
      }
    }
    return out;
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
    int newIndex = 0;
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
      newIndex = cards.length - 1;
    });
    _triggerSpawnAnimation(newIndex);
    _saveBoard();
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _theme.deviceBg,
        title: Text(
          'RESET?',
          style: TextStyle(
            color: _theme.textPrimary,
            fontSize: 14,
            fontFamily: 'SpaceMono',
          ),
        ),
        content: Text(
          'Board will be reset.',
          style: TextStyle(color: _theme.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: TextStyle(color: _theme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('board_cards');
              await prefs.remove('board_background');
              _selectCard(null);
              setState(() {
                cards = [];
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
            child: const Text('RESET', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ★ 카드 편집 핸들 (선택 시 카드 주변에 표시)
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
          border: Border.all(color: _theme.accent.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: _theme.accent.withOpacity(0.3), blurRadius: 8),
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
          bg: Colors.red.shade700,
          iconColor: Colors.white,
          onTap: () {
            setState(() {
              cards.removeAt(index);
              if (index < _floatOffsets.length) _floatOffsets.removeAt(index);
            });
            _selectCard(null);
            _saveBoard();
          },
        ),
      ),
      Positioned(
        left: left - 14,
        top: top - 14,
        child: _handle(
          icon: Icons.arrow_downward,
          bg: _theme.buttonBg,
          iconColor: _theme.textPrimary,
          onTap: () {
            if (index > 0) {
              setState(() {
                final c = cards.removeAt(index);
                cards.insert(index - 1, c);
                if (index < _floatOffsets.length) {
                  final o = _floatOffsets.removeAt(index);
                  _floatOffsets.insert(index - 1, o);
                }
              });
              _selectCard(index - 1);
              _saveBoard();
            }
          },
        ),
      ),
      Positioned(
        left: left + 18,
        top: top - 14,
        child: _handle(
          icon: Icons.arrow_upward,
          bg: _theme.buttonBg,
          iconColor: _theme.textPrimary,
          onTap: () {
            if (index < cards.length - 1) {
              setState(() {
                final c = cards.removeAt(index);
                cards.insert(index + 1, c);
                if (index < _floatOffsets.length) {
                  final o = _floatOffsets.removeAt(index);
                  _floatOffsets.insert(index + 1, o);
                }
              });
              _selectCard(index + 1);
              _saveBoard();
            }
          },
        ),
      ),
      Positioned(
        left: right - 14,
        top: bottom - 14,
        child: _handle(
          icon: Icons.open_in_full,
          bg: _theme.buttonBg,
          iconColor: _theme.textPrimary,
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
          bg: _theme.buttonBg,
          iconColor: _theme.textPrimary,
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
      if (background.imageAsset != null && _hasAsset(background.imageAsset))
        return Image.asset(
          background.imageAsset!,
          fit: BoxFit.cover,
          // 배경 에셋이 없는 환경에서는 무드 그라디언트로 폴백
          errorBuilder: (context, error, stackTrace) => CustomPaint(
            painter: BackgroundPainter(
              moodBackgrounds[_currentMood] ?? BoardBackground(),
            ),
          ),
        );
    }
    return CustomPaint(painter: BackgroundPainter(background));
  }

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
      case 'manifestation':
        {
          final progress = total <= 1 ? 0.0 : index / (total - 1);
          final delay = (progress * 0.6).clamp(0.0, 0.6);
          final end = (delay + 0.35).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);
          final curved = _StickerCurve().transform(t);
          final angle = floatOffset * 2 - pi;
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
      case 'that_girl':
        {
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
      case 'cyber_dream':
        {
          final progress = total <= 1 ? 0.0 : index / (total - 1);
          final delay = (progress * 0.4).clamp(0.0, 0.4);
          final end = (delay + 0.5).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);
          double glitchX = 0.0, glitchY = 0.0, glitchOpacity = 0.0;
          if (t < 0.15) {
            glitchOpacity = 0.0;
          } else if (t < 0.3) {
            glitchOpacity = 0.7;
            glitchX = sin(floatOffset * 5) * 120.0;
            glitchY = cos(floatOffset * 3) * 80.0;
          } else if (t < 0.45) {
            glitchOpacity = 0.2;
            glitchX = -sin(floatOffset * 4) * 60.0;
            glitchY = cos(floatOffset * 2) * 40.0;
          } else if (t < 0.6) {
            glitchOpacity = 0.9;
            glitchX = cos(floatOffset * 3) * 40.0;
            glitchY = sin(floatOffset * 5) * 30.0;
          } else {
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
      case 'wanderlust':
        {
          final progress = total <= 1 ? 0.0 : index / (total - 1);
          final delay = (progress * 0.65).clamp(0.0, 0.65);
          final end = (delay + 0.35).clamp(delay + 0.01, 1.0);
          final t = ((animValue - delay) / (end - delay)).clamp(0.0, 1.0);
          final curved = Curves.easeOutQuart.transform(t);
          final riseDist = (1.0 - curved) * 150.0;
          final sway = sin(t * pi * 1.5 + floatOffset) * 12.0 * (1.0 - curved);
          return {
            'opacity': t < 0.4 ? Curves.easeIn.transform(t / 0.4) : 1.0,
            'scale': 0.85 + curved * 0.15,
            'dx': sway,
            'dy': riseDist,
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

  // ★ Claude Design: 상단 바
  Widget _buildGameHeader() {
    // 휴대폰 폭에서는 무드 이름과 장식 LED를 줄여 한 줄에 맞춘다.
    final compact = MediaQuery.of(context).size.width < 560;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          // 왼쪽: LED + 타이틀
          Row(
            children: [
              AnimatedBuilder(
                animation: _neonController,
                builder: (_, __) {
                  final ledColor = _theme.accent;
                  final glow = (0.5 + _neonController.value * 0.5).clamp(
                    0.0,
                    1.0,
                  );
                  return Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: ledColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ledColor.withOpacity(glow),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // VISION BOARD - Press Start 2P 스타일 (Space Mono fallback)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'VISION',
                      style: TextStyle(
                        color: _theme.textPrimary,
                        fontSize: 13,
                        fontFamily: 'SpaceMono',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    TextSpan(
                      text: ' BOARD',
                      style: TextStyle(
                        color: _theme.accent,
                        fontSize: 13,
                        fontFamily: 'SpaceMono',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // 오른쪽: 현재 무드 배지 + dots
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _theme.accent.withOpacity(0.4)),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moodLabels[_currentMood]?.split(' ').first ?? '',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      moodLabels[_currentMood]?.split(' ').last ?? '',
                      style: TextStyle(
                        color: _theme.textPrimary,
                        fontSize: 11,
                        fontFamily: 'SpaceMono',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // 상태 LED 3개
              Row(
                children: [
                  // ★ 사운드 토글
                  GestureDetector(
                    onTap: () {
                      setState(() => WebSynth.instance.enabled = !WebSynth.instance.enabled);
                      if (_soundOn) _buttonBlip();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _soundOn
                            ? Icons.volume_up_sharp
                            : Icons.volume_off_sharp,
                        size: 17,
                        color: _theme.textSecondary,
                      ),
                    ),
                  ),
                  if (!compact) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _theme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _theme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 7),
                  ],
                  AnimatedBuilder(
                    animation: _savePulseController,
                    builder: (_, __) {
                      final ledColor =
                          particleConfigs[_currentMood]?.color ?? _theme.accent;
                      final blink = _savePulseController.isAnimating
                          ? (sin(_savePulseController.value * pi * 10) + 1) / 2
                          : 0.0;
                      return Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ledColor,
                          boxShadow: [
                            BoxShadow(
                              color: ledColor.withOpacity(0.7 + blink * 0.3),
                              blurRadius: 8 + blink * 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ★ Claude Design: 베젤
  Widget _buildScreenBezel({required Widget child}) {
    return AnimatedBuilder(
      animation: _savePulseController,
      builder: (context, _) {
        final pulse = (sin(_savePulseController.value * pi)).clamp(0.0, 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _theme.screenBorder, // bezel color
            boxShadow: [
              // inset 효과를 outer shadow로 표현
              BoxShadow(
                color: Colors.white.withOpacity(0.06),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                offset: const Offset(0, -3),
                blurRadius: 8,
              ),
              if (pulse > 0.01)
                BoxShadow(
                  color: _theme.glowColor.withOpacity(pulse * 0.9),
                  blurRadius: 30 + pulse * 30,
                  spreadRadius: 3,
                ),
            ],
          ),
          child: Stack(
            children: [
              // MOODCOLLAGE 텍스트 (베젤 상단)
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '— MOODCOLLAGE • DREAMOS v6 —',
                    style: TextStyle(
                      color: _theme.textSecondary.withOpacity(0.5),
                      fontSize: 7,
                      fontFamily: 'SpaceMono',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              // 화면 본체
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _theme.glowColor.withOpacity(0.4),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // ★ 공유 보드 배너 (친구 링크로 들어왔을 때)
  // ─────────────────────────────────────────────
  Widget _buildSharedBanner() {
    final t = _theme;
    final sharedMood = diagMoods[_sharedResultMood];
    final sharedLabel = sharedMood == null ? null : sharedMood.title;
    final compat = (_myResultMood != null && _sharedResultMood != null)
        ? compatLine(_myResultMood!, _sharedResultMood!)
        : null;
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.accent.withOpacity(0.8)),
            boxShadow: [BoxShadow(color: t.glowColor, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sharedLabel != null
                    ? tr('📡 친구의 보드 — $sharedLabel', '📡 INCOMING BOARD — $sharedLabel')
                    : tr('📡 친구의 보드', '📡 INCOMING BOARD'),
                style: TextStyle(
                  color: t.accent,
                  fontSize: 11,
                  fontFamily: 'SpaceMono',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (compat != null) ...[
                const SizedBox(height: 6),
                Text(
                  compat,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 10,
                    fontFamily: 'SpaceMono',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              GameButton3D(
                label: tr('나도 만들기 ▸', 'MAKE MINE ▸'),
                onTap: _exitSharedView,
                width: 110,
                height: 30,
                theme: t,
                fontSize: 9,
                isActive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ★ 보드 화면(베젤 + 보드) — 가로/세로 레이아웃이 공유한다.
  Widget _buildBoardScreen() {
    return _buildScreenBezel(
                    child: LayoutBuilder(
                      builder: (context, inner) {
                        final screenW = inner.maxWidth;
                        final screenH = inner.maxHeight;
                        _boardW = screenW;
                        _boardH = screenH;
                        return GestureDetector(
                          onTap: () => _selectCard(null),
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
                                      Positioned.fill(
                                        child: _buildBackground(),
                                      ),
                                      AnimatedBuilder(
                                        animation: Listenable.merge([
                                          _introController,
                                          _floatController,
                                          _neonController,
                                          _spotlightController,
                                          _selectScaleController,
                                          _spawnController,
                                        ]),
                                        builder: (context, _) {
                                          final spotlightVal =
                                              _spotlightController.value;
                                          return Stack(
                                            children: List.generate(cards.length, (
                                              index,
                                            ) {
                                              final card = cards[index];
                                              final isSelected =
                                                  selectedIndex == index;
                                              final px = card.x(screenW);
                                              final py = card.y(screenH);
                                              final pw = card.width(screenW);
                                              final ph = card.height(screenW);
                                              final total = cards.length.clamp(
                                                1,
                                                9999,
                                              );
                                              final floatOffset =
                                                  index < _floatOffsets.length
                                                  ? _floatOffsets[index]
                                                  : 0.0;
                                              final iv = _calcIntroValues(
                                                index,
                                                total,
                                                _introController.value,
                                                screenW,
                                                screenH,
                                                card,
                                              );
                                              final introOpacity =
                                                  (iv['opacity']! as double)
                                                      .clamp(0.0, 1.0);
                                              final scale =
                                                  (iv['scale']! as double)
                                                      .clamp(0.0, 1.5);
                                              final introDx =
                                                  iv['dx']! as double;
                                              final introDy =
                                                  iv['dy']! as double;
                                              final introRotate =
                                                  iv['rotate']! as double;
                                              final floatBlend = introOpacity
                                                  .clamp(0.0, 1.0);
                                              final floatY = isSelected
                                                  ? 0.0
                                                  : sin(
                                                          _floatController
                                                                      .value *
                                                                  pi +
                                                              floatOffset,
                                                        ) *
                                                        _floatAmplitude *
                                                        floatBlend;
                                              final floatRot = isSelected
                                                  ? 0.0
                                                  : sin(
                                                          _floatController
                                                                      .value *
                                                                  pi +
                                                              floatOffset +
                                                              1.0,
                                                        ) *
                                                        0.008 *
                                                        floatBlend;
                                              final neonFlicker =
                                                  card.style == CardStyle.neon
                                                  ? _neonIntensityBase +
                                                        sin(
                                                              _neonController
                                                                          .value *
                                                                      pi *
                                                                      2 +
                                                                  floatOffset,
                                                            ) *
                                                            (1.0 -
                                                                _neonIntensityBase)
                                                  : 1.0;
                                              final dimOpacity =
                                                  selectedIndex != null
                                                  ? (isSelected
                                                        ? 1.0
                                                        : (1.0 -
                                                              spotlightVal *
                                                                  0.65))
                                                  : 1.0;
                                              final selectCurve = Curves
                                                  .elasticOut
                                                  .transform(
                                                    _selectScaleController
                                                        .value,
                                                  );
                                              final selectScale = isSelected
                                                  ? (1.0 + selectCurve * 0.1)
                                                  : 1.0;
                                              final isDragging =
                                                  draggingIndex == index;
                                              final dragScale = isDragging
                                                  ? 1.22
                                                  : 1.0;
                                              final isSpawning =
                                                  spawnIndex == index;
                                              final spawnT = Curves.elasticOut
                                                  .transform(
                                                    _spawnController.value
                                                        .clamp(0.0, 1.0),
                                                  );
                                              final spawnScale = isSpawning
                                                  ? (0.05 + spawnT * 0.95)
                                                  : 1.0;
                                              final spawnOpacity = isSpawning
                                                  ? _spawnController.value
                                                        .clamp(0.0, 1.0)
                                                  : 1.0;
                                              final spawnRiseY = isSpawning
                                                  ? (1.0 -
                                                            _spawnController
                                                                .value
                                                                .clamp(
                                                                  0.0,
                                                                  1.0,
                                                                )) *
                                                        60.0
                                                  : 0.0;
                                              final dragLift = isDragging
                                                  ? -10.0
                                                  : 0.0;

                                              return Positioned(
                                                left: px + introDx,
                                                top:
                                                    py +
                                                    introDy +
                                                    floatY +
                                                    spawnRiseY +
                                                    dragLift,
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () => _selectCard(
                                                    selectedIndex == index
                                                        ? null
                                                        : index,
                                                  ),
                                                  onDoubleTap: () {
                                                    if (card.text != null)
                                                      _showTextDialog(
                                                        editIndex: index,
                                                      );
                                                  },
                                                  onPanStart: (_) => setState(
                                                    () => draggingIndex = index,
                                                  ),
                                                  onPanUpdate: (d) {
                                                    setState(() {
                                                      card.xRatio =
                                                          ((card.xRatio *
                                                                          screenW +
                                                                      d
                                                                          .delta
                                                                          .dx) /
                                                                  screenW)
                                                              .clamp(0.0, 1.0);
                                                      card.yRatio =
                                                          ((card.yRatio *
                                                                          screenH +
                                                                      d
                                                                          .delta
                                                                          .dy) /
                                                                  screenH)
                                                              .clamp(0.0, 1.0);
                                                    });
                                                  },
                                                  onPanEnd: (_) {
                                                    setState(
                                                      () =>
                                                          draggingIndex = null,
                                                    );
                                                    _saveBoard();
                                                  },
                                                  child: Opacity(
                                                    opacity:
                                                        (introOpacity *
                                                                dimOpacity *
                                                                spawnOpacity)
                                                            .clamp(0.0, 1.0),
                                                    child: AnimatedScale(
                                                      scale:
                                                          scale *
                                                          selectScale *
                                                          dragScale *
                                                          spawnScale,
                                                      duration: const Duration(
                                                        milliseconds: 90,
                                                      ),
                                                      curve: Curves.easeOut,
                                                      child: AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 90,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          boxShadow: isDragging
                                                              ? [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                          0.65,
                                                                        ),
                                                                    blurRadius:
                                                                        30,
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          18,
                                                                        ),
                                                                    spreadRadius:
                                                                        2,
                                                                  ),
                                                                ]
                                                              : [],
                                                        ),
                                                        child: Transform.rotate(
                                                          angle:
                                                              introRotate +
                                                              floatRot,
                                                          child: Stack(
                                                            clipBehavior:
                                                                Clip.none,
                                                            children: [
                                                              if (isSelected)
                                                                Positioned(
                                                                  left: -3,
                                                                  top: -3,
                                                                  right: -3,
                                                                  bottom: -3,
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            4,
                                                                          ),
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          color: _theme.glowColor.withOpacity(
                                                                            0.7 *
                                                                                spotlightVal,
                                                                          ),
                                                                          blurRadius:
                                                                              16,
                                                                          spreadRadius:
                                                                              2,
                                                                        ),
                                                                      ],
                                                                      border: Border.all(
                                                                        color: _theme
                                                                            .accent
                                                                            .withOpacity(
                                                                              0.8 *
                                                                                  spotlightVal,
                                                                            ),
                                                                        width:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              card.imageUrl !=
                                                                          null ||
                                                                      card.imageBase64 !=
                                                                          null
                                                                  ? _buildPhotoCard(
                                                                      card,
                                                                      pw,
                                                                      ph,
                                                                    )
                                                                  : _buildSpecialTextCard(
                                                                      text: card
                                                                          .text!,
                                                                      style: card
                                                                          .style,
                                                                      textColor:
                                                                          Color(
                                                                            card.textColor,
                                                                          ),
                                                                      paperColor:
                                                                          Color(
                                                                            card.paperColor,
                                                                          ),
                                                                      w: pw,
                                                                      h: ph,
                                                                      neonFlicker:
                                                                          neonFlicker,
                                                                    ),
                                                            ],
                                                          ),
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
                                      // 파티클
                                      Positioned.fill(
                                        child: ParticleOverlay(
                                          mood: _currentMood,
                                          accent: _theme.accent,
                                          accent2: _theme.accent2,
                                        ),
                                      ),
                                      // ★ bloom (HTML: mix-blend-mode:screen)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: AnimatedBuilder(
                                            animation:
                                                _moodTransitionController,
                                            builder: (_, __) => ColorFiltered(
                                              colorFilter: ColorFilter.mode(
                                                Colors.transparent,
                                                BlendMode.screen,
                                              ),
                                              child: CustomPaint(
                                                painter: _BloomPainter(
                                                  color: _theme.accent,
                                                  opacity: 0.55,
                                                ),
                                                size: Size.infinite,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // ★ vignette (inset 방식 - 가장자리만 어둡게)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                radius: 1.1,
                                                colors: [
                                                  Colors.transparent,
                                                  _theme.vigColor.withOpacity(
                                                    0.55,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // ★ 상단 유리 반사광
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        height: 80,
                                        child: IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.white.withOpacity(
                                                    0.09,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (selectedIndex != null &&
                                  selectedIndex! < cards.length)
                                ..._buildControls(
                                  cards[selectedIndex!],
                                  selectedIndex!,
                                  screenW,
                                  screenH,
                                ),
                              // ★ 무드 전환 트랜지션 — RepaintBoundary 밖, 맨 위
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _moodTransitionController,
                                  builder: (context, _) => IgnorePointer(
                                    child:
                                        _moodTransitionController.value > 0.001
                                        ? CustomPaint(
                                            painter: MoodTransitionPainter(
                                              t: _moodTransitionController
                                                  .value,
                                              color: _theme.accent,
                                            ),
                                            size: Size.infinite,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                              // ★ 공유 보드 배너 (친구 링크 뷰)
                              if (_isSharedView && !_showQuiz)
                                _buildSharedBanner(),
                              // ★ DREAM OS 진단 오버레이 — 항상 최상단
                              if (_showQuiz)
                                DiagnosisScreen(
                                  palette: _diagPalette(_currentMood),
                                  paletteOf: _diagPalette,
                                  controller: _diagController,
                                  onResult: _onDiagResult,
                                  onBuild: _onDiagBuild,
                                  onClose: _onDiagClose,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
  }

  // A / B — 기울어진 둥근 버튼 (콘솔 오른쪽 위)
  Widget _buildAbCluster() {
    return Transform.rotate(
      angle: -18 * pi / 180,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: RoundPadButton(
              label: 'B',
              color: _theme.accent,
              theme: _theme,
              onTap: () {
                if (!_showQuiz) _buttonBlip();
                _consoleB();
              },
            ),
          ),
          const SizedBox(width: 16),
          RoundPadButton(
            label: 'A',
            color: _theme.accent2,
            theme: _theme,
            onTap: () {
              if (!_showQuiz) _buttonBlip();
              _consoleA();
            },
          ),
        ],
      ),
    );
  }

  // A/B (+ 진단이 끝난 뒤에는 MENU) — 게임기처럼 단순하게
  Widget _buildRightDeck() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAbCluster(),
        if (!_showQuiz) ...[
          const SizedBox(height: 22),
          Transform.rotate(
            angle: -18 * pi / 180,
            child: PadPillButton(
              label: _isExporting ? 'SAVING…' : 'MENU',
              theme: _theme,
              onTap: () {
                _buttonBlip();
                _showMenuSheet();
              },
            ),
          ),
        ],
      ],
    );
  }

  // MENU — 큰 타일 6개 (ADD / BG / DIAG / EXPORT / SHARE / RESET)
  Future<void> _showMenuSheet() {
    final t = _theme;
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (icon: Icons.add_box_sharp, label: tr('추가', 'ADD'), onTap: _showAddSheet),
      (icon: Icons.wallpaper_sharp, label: tr('배경', 'BG'), onTap: _showBgDialog),
      (icon: Icons.psychology_sharp, label: tr('진단', 'DIAG'), onTap: _startQuiz),
      (icon: Icons.ios_share_sharp, label: tr('내보내기', 'EXPORT'), onTap: _showExportSheet),
      (icon: Icons.share_sharp, label: tr('공유', 'SHARE'), onTap: _shareBoard),
      (icon: Icons.restart_alt_sharp, label: tr('초기화', 'RESET'), onTap: _confirmReset),
    ];
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.deviceBg2,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MENU',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 11,
                  color: t.accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  const gap = 12.0;
                  final w = (c.maxWidth - gap * 2) / 3;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final it in items)
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(ctx);
                            Future.microtask(it.onTap);
                          },
                          child: Container(
                            width: w,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: t.accent.withOpacity(.35)),
                              color: Colors.white.withOpacity(.04),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(it.icon, size: 30, color: t.accent),
                                const SizedBox(height: 10),
                                Text(
                                  it.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Jua',
                                    fontSize: 16,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ★ 가로 화면: [D-PAD] [ 보드 화면 ] [ A·B + 버튼 3×2 ]
  Widget _buildLandscapeDeck() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 128, child: Center(child: _build3DDPad())),
        Expanded(child: _buildBoardScreen()),
        SizedBox(
          width: 204,
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: _buildRightDeck()),
          ),
        ),
      ],
    );
  }

  // ★ 세로(휴대폰) 화면: 무드 → [D-PAD + 버튼 3×3]. 좁으면 줄바꿈.
  Widget _buildGameButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMoodPills(),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [_build3DDPad(), _buildRightDeck()],
        ),
      ],
    );
  }

  // 무드 pill — 한 줄, 넘치면 가로 스크롤(휴대폰), 남으면 가운데 정렬
  Widget _buildMoodPills() {
    final pills = [
      for (final e in moodLabels.entries) _moodPillButton(e.key, e.value),
    ];
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: c.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pills.length; i++) ...[
                if (i > 0) const SizedBox(width: 11),
                pills[i],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 선택지 시트 (ADD / EXPORT 공용)
  Future<void> _showChoiceSheet(
    String title,
    List<({IconData icon, String label, String sub, VoidCallback onTap})> items,
  ) {
    final t = _theme;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.deviceBg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 11,
                  color: t.accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _buttonBlip();
                      it.onTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.accent.withOpacity(.4)),
                        color: Colors.white.withOpacity(.04),
                      ),
                      child: Row(
                        children: [
                          Icon(it.icon, color: t.accent, size: 26),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.label,
                                  style: TextStyle(
                                    fontFamily: 'Jua',
                                    fontSize: 17,
                                    color: t.textPrimary,
                                  ),
                                ),
                                Text(
                                  it.sub,
                                  style: TextStyle(
                                    fontFamily: 'Jua',
                                    fontSize: 13,
                                    color: t.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddSheet() => _showChoiceSheet('ADD', [
    (
      icon: Icons.add_photo_alternate_sharp,
      label: tr('사진 올리기', 'Upload a photo'),
      sub: tr('내 사진을 보드에 붙여요', 'Pin your own photo to the board'),
      onTap: _pickImage,
    ),
    (
      icon: Icons.title_sharp,
      label: tr('글귀 추가', 'Add text'),
      sub: tr('좋아하는 문장을 카드로 만들어요', 'Turn a line you love into a card'),
      onTap: () => _showTextDialog(),
    ),
  ]);

  Future<void> _showExportSheet() => _showChoiceSheet('EXPORT', [
    (
      icon: Icons.image_sharp,
      label: tr('보드 이미지 (PNG)', 'Board image (PNG)'),
      sub: tr('지금 보드를 그대로 저장해요', 'Save the board as it looks now'),
      onTap: _exportAsPng,
    ),
    (
      icon: Icons.smartphone_sharp,
      label: tr('스토리용 9:16', 'Story image 9:16'),
      sub: tr('인스타 스토리에 맞춰 세로로 저장해요', 'Vertical frame for Instagram stories'),
      onTap: _exportStory,
    ),
  ]);

  // ★ Claude Design 스타일 pill 무드 버튼
  Widget _moodPillButton(String moodKey, String label) {
    final isActive = _currentMood == moodKey;
    final parts = label.split(' ');
    final emoji = parts.isNotEmpty ? parts[0] : '';
    final text = parts.length > 1 ? parts[1] : label;
    return GestureDetector(
      onTap: () => _applyMood(moodKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isActive ? _theme.accent : _theme.buttonBg.withOpacity(0.6),
          border: Border.all(
            color: isActive
                ? _theme.accent
                : _theme.buttonBorder.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _theme.glowColor,
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                color: isActive ? _theme.screenBorder : _theme.textSecondary,
                fontSize: 11,
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ Claude Design D-PAD: 중앙 구슬 + 그라디언트 버튼
  Widget _build3DDPad() {
    const moveStep = 0.018;
    const size = 108.0;
    const arm = 38.0;
    const center = 32.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 가로 바
          Positioned(
            top: arm,
            left: 0,
            child: _dpadArm(width: size, height: center),
          ),
          // 세로 바
          Positioned(
            left: arm,
            top: 0,
            child: _dpadArm(width: center, height: size),
          ),
          // 방향 버튼
          Positioned(
            top: 0,
            left: arm,
            child: DPadButton3D(
              icon: Icons.keyboard_arrow_up,
              theme: _theme,
              onTap: () => _moveSelectedCard(0, -moveStep),
              size: center,
            ),
          ),
          Positioned(
            bottom: 0,
            left: arm,
            child: DPadButton3D(
              icon: Icons.keyboard_arrow_down,
              theme: _theme,
              onTap: () => _moveSelectedCard(0, moveStep),
              size: center,
            ),
          ),
          Positioned(
            left: 0,
            top: arm,
            child: DPadButton3D(
              icon: Icons.keyboard_arrow_left,
              theme: _theme,
              onTap: () => _moveSelectedCard(-moveStep, 0),
              size: center,
            ),
          ),
          Positioned(
            right: 0,
            top: arm,
            child: DPadButton3D(
              icon: Icons.keyboard_arrow_right,
              theme: _theme,
              onTap: () => _moveSelectedCard(moveStep, 0),
              size: center,
            ),
          ),
          // ★ 중앙 구슬 (Claude Design: radial gradient accent + glow)
          Center(
            child: AnimatedBuilder(
              animation: _neonController,
              builder: (_, __) => Container(
                width: center,
                height: center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.35),
                    radius: 0.8,
                    colors: [_theme.accent, _theme.buttonBg],
                  ),
                  boxShadow: [
                    BoxShadow(color: _theme.screenBorder, spreadRadius: 3),
                    BoxShadow(
                      color: _theme.glowColor.withOpacity(
                        0.4 + _neonController.value * 0.3,
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dpadArm({required double width, required double height}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_theme.deviceBorder, _theme.buttonBg],
        ),
        boxShadow: [
          BoxShadow(color: _theme.buttonSide, offset: const Offset(0, 4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ★ 보드 로딩이 끝나면 인트로에 알린다 (HELLO 단계 진입 조건)
    if (!isLoading && !appReadyNotifier.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appReadyNotifier.value = true;
      });
    }
    if (isLoading)
      return Scaffold(
        backgroundColor: _theme.deviceBg,
        body: Center(child: CircularProgressIndicator(color: _theme.accent)),
      );

    return Scaffold(
      // ★ Claude Design: page radial gradient (전체 배경)
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.3),
            radius: 1.5,
            colors: [_theme.deviceBg, _theme.deviceBg2],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1760),
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 8 : 16,
                ),
                child: _buildConsole(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ★ Claude Design: 게임기 본체 전체 (shell gradient + 나사 + 광택)
  Widget _buildConsole() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.14, 1.0],
          colors: [_theme.deviceBorder, _theme.deviceBg, _theme.deviceBg2],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.10),
            offset: const Offset(0, 2),
            blurRadius: 0,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            offset: const Offset(0, -8),
            blurRadius: 22,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            offset: const Offset(0, 40),
            blurRadius: 80,
          ),
          BoxShadow(color: Colors.white.withOpacity(0.05), spreadRadius: 1),
        ],
      ),
      child: Stack(
        children: [
          // ★ 플라스틱 광택 (상단 + 하단 하이라이트)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.22, 0.78, 1.0],
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 나사 4개
          ..._buildScrews(),
          // 본체 콘텐츠
          Padding(
            padding: MediaQuery.of(context).size.width < 600
                ? const EdgeInsets.fromLTRB(12, 12, 12, 14)
                : const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: LayoutBuilder(
              builder: (context, box) {
                // 가로 화면: D-PAD·버튼을 화면 양옆에 두어 보드 화면을 최대한 크게.
                // 세로(휴대폰): 화면 아래에 쌓는다.
                final landscape =
                    box.maxWidth >= 720 && box.maxWidth >= box.maxHeight * 1.2;
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _buildGameHeader(),
                    Expanded(
                      child: landscape
                          ? _buildLandscapeDeck()
                          : _buildBoardScreen(),
                    ),
                    const SizedBox(height: 14),
                    landscape
                        ? _buildMoodPills()
                        : AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: _showQuiz
                                // 터치로는 카드를 직접 누르면 되므로 진단 화면을 넓게 쓴다.
                                ? const SizedBox(width: double.infinity)
                                : _buildGameButtons(),
                          ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ★ 나사 4개 (Claude Design 스타일 - radial gradient)
  List<Widget> _buildScrews() {
    const s = 9.0;
    const pad = 14.0;
    Widget screw(double? top, double? bottom, double? left, double? right) =>
        Positioned(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.3),
                radius: 0.8,
                colors: [Colors.white, Color(0x80000000)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
    return [
      screw(pad, null, pad, null),
      screw(pad, null, null, pad),
      screw(null, pad, pad, null),
      screw(null, pad, null, pad),
    ];
  }

  Widget _buildPhotoCard(BoardCard card, double w, double h) {
    // Claude Design 스타일: 무드 테마 cardFrame + 깊은 그림자
    return Container(
      width: w,
      height: h + 24,
      decoration: BoxDecoration(
        color: _theme.cardFrame,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _theme.cardFrame, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 14,
            offset: const Offset(3, 6),
          ),
          BoxShadow(
            color: _theme.accent.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 이미지 영역
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: card.imageBase64 != null
                  ? Image.memory(
                      base64Decode(card.imageBase64!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : !_hasAsset(card.imageUrl)
                  ? _placeholderTile()
                  : Image.asset(
                      card.imageUrl!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      // 에셋이 없는 환경(공유 링크로 열람 등)에서는
                      // Claude Design 스타일 그라디언트 타일로 대체
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholderTile(),
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null)
                              return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: child,
                            );
                          },
                    ),
            ),
          ),
          // Claude Design 스타일 캡션 바
          Container(
            height: 22,
            color: _theme.cardFrame,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
              _moodCaption(card.imageUrl),
              softWrap: false,
              style: TextStyle(
                color: _theme.accentDim,
                fontSize: 7,
                fontFamily: 'SpaceMono',
                letterSpacing: 1.5,
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  // ★ 에셋 없는 환경용 플레이스홀더 타일 (Claude Design HTML의 cardTile 스타일)
  Widget _placeholderTile() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_theme.accentDim, _theme.accent.withOpacity(0.55)],
        ),
      ),
      child: CustomPaint(
        painter: _StripeTilePainter(color: Colors.black.withOpacity(0.10)),
        size: Size.infinite,
      ),
    );
  }

  // Claude Design 스타일 캡션 (무드별 사전 텍스트)
  static const _captionSets = {
    'manifestation': [
      'DREAM HOME',
      'FIRST CLASS',
      'NEW ERA',
      'ABUNDANCE',
      'GLOW UP',
      'ALIGNED',
      'STAGE LIGHT',
      'SOULMATE',
      'THE VIEW',
      'BOSS ERA',
    ],
    'soft_life': [
      'SLOW DAYS',
      'SOFT HOURS',
      'GOLDEN AGE',
      'REST MODE',
      'PURE JOY',
      'NOURISH',
      'PEACE OUT',
      'BLOOM',
    ],
    'that_girl': [
      '5 A.M',
      'DISCIPLINE',
      'HUSTLE MODE',
      'DEBT FREE',
      'LEVEL UP',
      'SHOW UP',
      'WORK HARD',
      'ALIGNED',
    ],
    'cyber_dream': [
      'SYSTEM ON',
      'ENTER VOID',
      'GLITCH ON',
      'CTRL+ALT',
      'NEON LIFE',
      'OVERRIDE',
      'UPLOAD',
      'BOOT UP',
    ],
    'wanderlust': [
      'KEEP MOVING',
      'OPEN ROADS',
      'NEW HORIZON',
      'WANDER ON',
      'EXPLORE',
      'DEPARTURE',
      'FLOW STATE',
      'ONWARDS',
    ],
  };

  String _moodCaption(String? imageUrl) {
    if (imageUrl == null) return '';
    final set = _captionSets[_currentMood] ?? _captionSets['manifestation']!;
    final idx = imageUrl.hashCode.abs() % set.length;
    return set[idx];
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
          backgroundColor: _theme.deviceBg,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'EDIT TEXT' : 'ADD TEXT',
                  style: TextStyle(
                    color: _theme.textPrimary,
                    fontSize: 14,
                    fontFamily: 'SpaceMono',
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
                            style: TextStyle(color: _theme.textPrimary),
                            maxLines: 4,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Enter text...',
                              hintStyle: TextStyle(color: _theme.textSecondary),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _theme.buttonBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _theme.accent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'STYLE',
                            style: TextStyle(
                              color: _theme.textSecondary,
                              fontSize: 11,
                              fontFamily: 'SpaceMono',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: CardStyle.values.map((s) {
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
                                        ? _theme.accent
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSel
                                          ? _theme.accent
                                          : _theme.buttonBorder,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    styleLabels[s]!,
                                    style: TextStyle(
                                      color: isSel
                                          ? _theme.deviceBg
                                          : _theme.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'TEXT COLOR',
                            style: TextStyle(
                              color: _theme.textSecondary,
                              fontSize: 11,
                              fontFamily: 'SpaceMono',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
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
                                              ? _theme.accent
                                              : Colors.grey.withOpacity(0.4),
                                          width: 2,
                                        ),
                                      ),
                                      child: selectedTextColor == c
                                          ? Icon(
                                              Icons.check,
                                              size: 12,
                                              color: c.computeLuminance() > 0.5
                                                  ? Colors.black
                                                  : Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREVIEW',
                          style: TextStyle(
                            color: _theme.textSecondary,
                            fontSize: 11,
                            fontFamily: 'SpaceMono',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 160,
                          height: 200,
                          color: _theme.deviceBg2,
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
                      child: Text(
                        'CANCEL',
                        style: TextStyle(color: _theme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _theme.accent,
                      ),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          final rng = Random();
                          int? newIndex;
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
                              newIndex = cards.length - 1;
                            }
                          });
                          _saveBoard();
                          if (newIndex != null)
                            _triggerSpawnAnimation(newIndex!);
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        isEdit ? 'SAVE' : 'ADD',
                        style: TextStyle(
                          color: _theme.deviceBg,
                          fontFamily: 'SpaceMono',
                        ),
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
          backgroundColor: _theme.deviceBg,
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BACKGROUND',
                    style: TextStyle(
                      color: _theme.textPrimary,
                      fontSize: 14,
                      fontFamily: 'SpaceMono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                        withData: true,
                      );
                      if (result != null) {
                        final bytes = result.files.first.bytes;
                        if (bytes != null)
                          setDialogState(() {
                            selectedType = BgType.image;
                            selectedImageBase64 = base64Encode(bytes);
                          });
                      }
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _theme.buttonBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _theme.buttonBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wallpaper,
                            color: _theme.textPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedType == BgType.image &&
                                    selectedImageBase64 != null
                                ? 'Image uploaded ✓'
                                : 'Upload Image',
                            style: TextStyle(
                              color: _theme.textPrimary,
                              fontSize: 12,
                              fontFamily: 'SpaceMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PATTERN',
                    style: TextStyle(
                      color: _theme.textSecondary,
                      fontSize: 11,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BgType.values.where((t) => t != BgType.image).map(
                      (t) {
                        final isSel = selectedType == t;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedType = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSel ? _theme.accent : _theme.buttonBg,
                              border: Border.all(
                                color: isSel
                                    ? _theme.accent
                                    : _theme.buttonBorder,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bgTypeLabels[t]!,
                              style: TextStyle(
                                color: isSel
                                    ? _theme.deviceBg
                                    : _theme.textPrimary,
                                fontSize: 11,
                                fontFamily: 'SpaceMono',
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PRESETS',
                    style: TextStyle(
                      color: _theme.textSecondary,
                      fontSize: 11,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
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
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _theme.buttonBorder),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: CustomPaint(
                                size: const Size(52, 52),
                                painter: BackgroundPainter(presetBg),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PREVIEW',
                    style: TextStyle(
                      color: _theme.textSecondary,
                      fontSize: 11,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 80,
                      width: double.infinity,
                      child:
                          selectedType == BgType.image &&
                              selectedImageBase64 != null
                          ? Image.memory(
                              base64Decode(selectedImageBase64!),
                              fit: BoxFit.cover,
                            )
                          : CustomPaint(
                              size: const Size(double.infinity, 80),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(color: _theme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _theme.accent,
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
                        child: Text(
                          'APPLY',
                          style: TextStyle(
                            color: _theme.deviceBg,
                            fontFamily: 'SpaceMono',
                          ),
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

  // ★ 좁은 화면(휴대폰)에서 카드 폭이 줄어도 글자가 잘리지 않도록,
  // 최소 기준 크기로 그린 뒤 비율을 유지한 채 축소한다.
  Widget _buildSpecialTextCard({
    required String text,
    required CardStyle style,
    required Color textColor,
    required Color paperColor,
    required double w,
    required double h,
    required double neonFlicker,
  }) {
    const minW = 150.0, minH = 60.0;
    if (w >= minW && h >= minH) {
      return _buildSpecialTextCardRaw(
        text: text,
        style: style,
        textColor: textColor,
        paperColor: paperColor,
        w: w,
        h: h,
        neonFlicker: neonFlicker,
      );
    }
    return SizedBox(
      width: w,
      height: h,
      child: FittedBox(
        fit: BoxFit.contain,
        child: _buildSpecialTextCardRaw(
          text: text,
          style: style,
          textColor: textColor,
          paperColor: paperColor,
          w: max(w, minW),
          h: max(h, minH),
          neonFlicker: neonFlicker,
        ),
      ),
    );
  }

  Widget _buildSpecialTextCardRaw({
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
}

// ★ 무드 전환 시 카트리지 교체 느낌 - 암전 + 스캔라인
// ★ 플레이스홀더 타일의 대각선 스트라이프 (HTML repeating-linear-gradient 대응)
class _StripeTilePainter extends CustomPainter {
  final Color color;
  _StripeTilePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 7;
    final maxD = size.width + size.height;
    for (double d = 0; d < maxD; d += 14) {
      canvas.drawLine(Offset(d, 0), Offset(d - size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripeTilePainter old) => old.color != color;
}

class MoodTransitionPainter extends CustomPainter {
  final double t; // 0(평소) → 1(완전 암전) → 0(복귀)
  final Color color;
  MoodTransitionPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.001) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 암전 (검은 페이드)
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withOpacity((t * 0.92).clamp(0.0, 0.92)),
    );

    // 스캔라인이 위에서 아래로 휙 지나가는 효과
    final scanY = t * size.height * 1.4 - size.height * 0.2;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.55),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, scanY - 60, size.width, 120));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 60, size.width, 120), scanPaint);

    // 가는 가로 스캔라인 텍스처 (은은하게)
    final linePaint = Paint()..color = color.withOpacity(0.06 * t);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MoodTransitionPainter old) =>
      old.t != t || old.color != color;
}

class _BloomPainter extends CustomPainter {
  final Color color;
  final double opacity;
  const _BloomPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // HTML: radial-gradient 60% 50% at 50% 6%, accent → transparent
    // mix-blend-mode: screen → 밝은 부분만 더해짐
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.88),
        radius: 0.7,
        colors: [color.withOpacity(opacity), Colors.transparent],
      ).createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _BloomPainter old) =>
      old.color != color || old.opacity != opacity;
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

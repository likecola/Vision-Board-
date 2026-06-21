import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class MoodTheme {
  final Color deviceBg;
  final Color deviceBorder;
  final Color screenBg;
  final Color screenBorder;
  final Color accent;
  final Color accentDim;
  final Color buttonBg;
  final Color buttonBorder;
  final Color buttonTop; // ★ 버튼 상단면 (밝은색)
  final Color buttonSide; // ★ 버튼 측면 (어두운색, 3D 효과)
  final Color textPrimary;
  final Color textSecondary;

  const MoodTheme({
    required this.deviceBg,
    required this.deviceBorder,
    required this.screenBg,
    required this.screenBorder,
    required this.accent,
    required this.accentDim,
    required this.buttonBg,
    required this.buttonBorder,
    required this.buttonTop,
    required this.buttonSide,
    required this.textPrimary,
    required this.textSecondary,
  });
}

const moodThemes = {
  'manifestation': MoodTheme(
    deviceBg: Color(0xFF1a1a2e),
    deviceBorder: Color(0xFF2d2d4e),
    screenBg: Color(0xFF0a0a18),
    screenBorder: Color(0xFF3d3d6e),
    accent: Color(0xFFa78bfa),
    accentDim: Color(0xFF4a3a8a),
    buttonBg: Color(0xFF2a2a4a),
    buttonBorder: Color(0xFF5a4aaa),
    buttonTop: Color(0xFF3a3a6a),
    buttonSide: Color(0xFF0a0a1a),
    textPrimary: Color(0xFFc4b5fd),
    textSecondary: Color(0xFF6b6ba8),
  ),
  'soft_life': MoodTheme(
    deviceBg: Color(0xFF2e2018),
    deviceBorder: Color(0xFF4a3020),
    screenBg: Color(0xFF1a100a),
    screenBorder: Color(0xFF6a4a30),
    accent: Color(0xFFd4956a),
    accentDim: Color(0xFF6a3a18),
    buttonBg: Color(0xFF3a2818),
    buttonBorder: Color(0xFF8a5a38),
    buttonTop: Color(0xFF4a3828),
    buttonSide: Color(0xFF1a0808),
    textPrimary: Color(0xFFf0c8a0),
    textSecondary: Color(0xFF8a6848),
  ),
  'that_girl': MoodTheme(
    deviceBg: Color(0xFF111111),
    deviceBorder: Color(0xFF2a2a2a),
    screenBg: Color(0xFF080808),
    screenBorder: Color(0xFF3a3a3a),
    accent: Color(0xFFc8a97e),
    accentDim: Color(0xFF4a3a20),
    buttonBg: Color(0xFF1a1a1a),
    buttonBorder: Color(0xFF5a4a28),
    buttonTop: Color(0xFF2a2a2a),
    buttonSide: Color(0xFF000000),
    textPrimary: Color(0xFFe8d0a8),
    textSecondary: Color(0xFF6a5a38),
  ),
  'cyber_dream': MoodTheme(
    deviceBg: Color(0xFF0d0520),
    deviceBorder: Color(0xFF1a0a40),
    screenBg: Color(0xFF050010),
    screenBorder: Color(0xFF2a0a50),
    accent: Color(0xFF00f5ff),
    accentDim: Color(0xFF003a4a),
    buttonBg: Color(0xFF100a28),
    buttonBorder: Color(0xFF00a8cc),
    buttonTop: Color(0xFF1a1038),
    buttonSide: Color(0xFF020008),
    textPrimary: Color(0xFF80ffff),
    textSecondary: Color(0xFF306878),
  ),
  'wanderlust': MoodTheme(
    deviceBg: Color(0xFF0e1e2a),
    deviceBorder: Color(0xFF1a3040),
    screenBg: Color(0xFF080e14),
    screenBorder: Color(0xFF2a4a60),
    accent: Color(0xFF6baed6),
    accentDim: Color(0xFF1a3a50),
    buttonBg: Color(0xFF142030),
    buttonBorder: Color(0xFF3a6a90),
    buttonTop: Color(0xFF1e3040),
    buttonSide: Color(0xFF040e18),
    textPrimary: Color(0xFFa8d8f0),
    textSecondary: Color(0xFF3a6880),
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

  const GameButton3D({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 60,
    this.height = 30,
    this.isActive = false,
    required this.theme,
    this.fontSize = 8,
  });

  @override
  State<GameButton3D> createState() => _GameButton3DState();
}

class _GameButton3DState extends State<GameButton3D> {
  bool _pressed = false;
  static const _depth = 5.0; // ★ 3D 깊이

  @override
  Widget build(BuildContext context) {
    final topColor = widget.isActive
        ? widget.theme.accent
        : widget.theme.buttonTop;
    final sideColor = widget.isActive
        ? widget.theme.accent.withOpacity(0.4)
        : widget.theme.buttonSide;

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
            // ★ 측면 (바닥 레이어) - 항상 고정
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.theme.buttonBorder.withOpacity(0.6),
                    width: 1,
                  ),
                ),
              ),
            ),
            // ★ 표면 (위 레이어) - 눌리면 아래로 이동
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
                    colors: [
                      topColor,
                      Color.lerp(topColor, Colors.black, 0.25)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.isActive
                        ? widget.theme.accent
                        : widget.theme.buttonBorder,
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // ★ 미세한 스캔라인 텍스처 (레트로 기기 질감)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: CustomPaint(painter: _ButtonScanlinePainter()),
                      ),
                    ),
                    Center(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.isActive
                              ? widget.theme.deviceBg
                              : widget.theme.textPrimary,
                          fontSize: widget.fontSize,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

  const DPadButton3D({
    super.key,
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  State<DPadButton3D> createState() => _DPadButton3DState();
}

class _DPadButton3DState extends State<DPadButton3D> {
  bool _pressed = false;
  Timer? _repeatTimer;
  static const _depth = 4.0;

  void _startRepeating() {
    widget.onTap(); // 첫 탭 즉시 실행
    _repeatTimer?.cancel();
    // ★ 길게 누르면 350ms 후부터 80ms 간격으로 연속 이동
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
        width: 24,
        height: 24 + _depth,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: widget.theme.buttonSide,
                  border: Border.all(
                    color: widget.theme.buttonBorder.withOpacity(0.5),
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
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.theme.buttonTop,
                      Color.lerp(widget.theme.buttonTop, Colors.black, 0.3)!,
                    ],
                  ),
                  border: Border.all(color: widget.theme.buttonBorder),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.theme.textSecondary,
                  size: 14,
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
enum ParticleKind { star, bubble, dust }

// ★ 무드별 이동 패턴
enum MotionType { radiate, drift, still, glitch, swirl }

class Particle {
  double x, y; // 0~1 ratio (기준 위치)
  double size;
  double speed; // 0~1 per loop
  double phase; // 깜빡임/움직임 위상
  double drift; // 좌우 흔들림 폭
  double angle; // radiate용 발산 각도
  ParticleKind kind;
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.drift,
    required this.angle,
    required this.kind,
  });
}

// ★ 무드별 파티클 설정
class ParticleConfig {
  final int count;
  final ParticleKind kind;
  final Color color;
  final double minSize, maxSize;
  final double speedMin, speedMax; // 한 바퀴 도는데 걸리는 시간(초)의 역수 느낌
  final double twinkleSpeed; // 깜빡임 속도
  final MotionType motion;
  const ParticleConfig({
    required this.count,
    required this.kind,
    required this.color,
    required this.minSize,
    required this.maxSize,
    required this.speedMin,
    required this.speedMax,
    required this.twinkleSpeed,
    required this.motion,
  });
}

const particleConfigs = {
  // 사방으로 퍼지며 반짝 - 화려하고 폭발적인 매니페스테이션
  'manifestation': ParticleConfig(
    count: 28,
    kind: ParticleKind.star,
    color: Color(0xFFD9B8FF),
    minSize: 1.5,
    maxSize: 3.5,
    speedMin: 0.15,
    speedMax: 0.35,
    twinkleSpeed: 1.4,
    motion: MotionType.radiate,
  ),
  // 좌우로 천천히 표류 - 바람에 날리는 듯한 소프트 라이프
  'soft_life': ParticleConfig(
    count: 14,
    kind: ParticleKind.bubble,
    color: Color(0xFFF0D9C0),
    minSize: 3.0,
    maxSize: 7.0,
    speedMin: 0.04,
    speedMax: 0.09,
    twinkleSpeed: 0.4,
    motion: MotionType.drift,
  ),
  // 거의 정지, 제자리 깜빡임 - 절제된 미니멀 댓걸
  'that_girl': ParticleConfig(
    count: 10,
    kind: ParticleKind.dust,
    color: Color(0xFFE8D0A0),
    minSize: 1.0,
    maxSize: 2.0,
    speedMin: 0.05,
    speedMax: 0.1,
    twinkleSpeed: 0.6,
    motion: MotionType.still,
  ),
  // 지그재그 + 순간이동 - 글리치한 사이버드림
  'cyber_dream': ParticleConfig(
    count: 36,
    kind: ParticleKind.star,
    color: Color(0xFF7FF5FF),
    minSize: 1.5,
    maxSize: 4.0,
    speedMin: 0.3,
    speedMax: 0.6,
    twinkleSpeed: 2.6,
    motion: MotionType.glitch,
  ),
  // 큰 원을 그리며 표류 - 안개처럼 부유하는 원더러스트
  'wanderlust': ParticleConfig(
    count: 20,
    kind: ParticleKind.bubble,
    color: Color(0xFFBFE0F5),
    minSize: 2.0,
    maxSize: 5.0,
    speedMin: 0.06,
    speedMax: 0.13,
    twinkleSpeed: 0.5,
    motion: MotionType.swirl,
  ),
};

// ★ 화면 전체 떠다니는 파티클 레이어
class ParticleOverlay extends StatefulWidget {
  final String mood;
  const ParticleOverlay({super.key, required this.mood});

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  List<Particle> _particles = [];
  String _builtForMood = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _buildParticles();
  }

  @override
  void didUpdateWidget(covariant ParticleOverlay old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _buildParticles();
  }

  void _buildParticles() {
    final cfg =
        particleConfigs[widget.mood] ?? particleConfigs['manifestation']!;
    final rng = Random(widget.mood.hashCode);
    _particles = List.generate(
      cfg.count,
      (i) => Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: cfg.minSize + rng.nextDouble() * (cfg.maxSize - cfg.minSize),
        speed: cfg.speedMin + rng.nextDouble() * (cfg.speedMax - cfg.speedMin),
        phase: rng.nextDouble() * pi * 2,
        drift: 0.02 + rng.nextDouble() * 0.04,
        angle: rng.nextDouble() * pi * 2,
        kind: cfg.kind,
      ),
    );
    _builtForMood = widget.mood;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg =
        particleConfigs[widget.mood] ?? particleConfigs['manifestation']!;
    if (_builtForMood != widget.mood) _buildParticles();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            t: _ctrl.value,
            color: cfg.color,
            twinkleSpeed: cfg.twinkleSpeed,
            motion: cfg.motion,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double t; // 0~1 루프
  final Color color;
  final double twinkleSpeed;
  final MotionType motion;
  ParticlePainter({
    required this.particles,
    required this.t,
    required this.color,
    required this.twinkleSpeed,
    required this.motion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      double dx, dy;

      switch (motion) {
        case MotionType.radiate:
          // ★ 중심에서 사방으로 퍼졌다가 다시 작아지며 사라짐 (폭발→리셋 루프)
          final travel = (t * p.speed * 4 + p.phase / (pi * 2)) % 1.0;
          final dist = sin(travel * pi) * 0.42; // 0 → 최대 → 0
          final cx = 0.5 + cos(p.angle) * dist;
          final cy = 0.5 + sin(p.angle) * dist * 0.8;
          dx = cx.clamp(0.0, 1.0) * size.width;
          dy = cy.clamp(0.0, 1.0) * size.height;
          break;

        case MotionType.drift:
          // ★ 좌우로 느긋하게 표류하며 위로 아주 천천히
          final travel = (t * p.speed * 3) % 1.0;
          final py = (1.0 - travel);
          final px = p.x + sin(t * pi * 2 * 0.3 + p.phase) * p.drift * 2.5;
          dx = px.clamp(0.0, 1.0) * size.width;
          dy = py * size.height;
          break;

        case MotionType.still:
          // ★ 거의 제자리, 아주 미세하게만 흔들림
          final px = p.x + sin(t * pi * 2 + p.phase) * p.drift * 0.4;
          final py = p.y + cos(t * pi * 2 * 0.7 + p.phase) * p.drift * 0.4;
          dx = px.clamp(0.0, 1.0) * size.width;
          dy = py.clamp(0.0, 1.0) * size.height;
          break;

        case MotionType.glitch:
          // ★ 지그재그로 움직이다 8단계마다 순간이동
          final step = (t * p.speed * 10 + p.phase).floor() % 8;
          final stepRng = Random(p.phase.hashCode + step);
          final jumpX = stepRng.nextDouble();
          final jumpY = stepRng.nextDouble();
          final localT = ((t * p.speed * 10 + p.phase) % 1.0);
          final zigzag = sin(localT * pi * 6) * 0.02;
          dx = (jumpX + zigzag).clamp(0.0, 1.0) * size.width;
          dy = (jumpY).clamp(0.0, 1.0) * size.height;
          break;

        case MotionType.swirl:
          // ★ 위로 떠오르며 큰 원을 그리듯 표류 (안개)
          final travel = (t * p.speed * 2.5) % 1.0;
          final py = (1.0 - travel);
          final swirl = t * pi * 2 * 0.5 + p.phase;
          final px = p.x + cos(swirl) * p.drift * 3.0;
          dx = px.clamp(0.0, 1.0) * size.width;
          dy = py * size.height;
          break;
      }

      final twinkle = (sin(t * pi * 2 * twinkleSpeed + p.phase) + 1) / 2; // 0~1
      final opacity = (0.25 + twinkle * 0.6).clamp(0.0, 1.0);

      if (p.kind == ParticleKind.star) {
        final paint = Paint()..color = color.withOpacity(opacity);
        // 십자 모양 별 반짝임
        canvas.drawCircle(Offset(dx, dy), p.size * 0.5, paint);
        final glow = Paint()
          ..color = color.withOpacity(opacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(dx, dy), p.size * 1.4, glow);
        final linePaint = Paint()
          ..color = color.withOpacity(opacity * 0.8)
          ..strokeWidth = 0.8;
        canvas.drawLine(
          Offset(dx - p.size, dy),
          Offset(dx + p.size, dy),
          linePaint,
        );
        canvas.drawLine(
          Offset(dx, dy - p.size),
          Offset(dx, dy + p.size),
          linePaint,
        );
      } else if (p.kind == ParticleKind.bubble) {
        final paint = Paint()
          ..color = color.withOpacity(opacity * 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dx, dy), p.size, paint);
        final ring = Paint()
          ..color = color.withOpacity(opacity * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawCircle(Offset(dx, dy), p.size, ring);
        final highlight = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.5);
        canvas.drawCircle(
          Offset(dx - p.size * 0.3, dy - p.size * 0.3),
          p.size * 0.25,
          highlight,
        );
      } else {
        final paint = Paint()..color = color.withOpacity(opacity * 0.6);
        canvas.drawCircle(Offset(dx, dy), p.size * 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter old) => true;
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
    if (selectedIndex == null || selectedIndex! >= cards.length) return;
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

  void _applyMood(String moodKey) {
    if (moodKey == _currentMood) return;
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

    _selectCard(null);

    // ★ 카트리지 교체 트랜지션: 암전(forward) → 중간에 콘텐츠 교체 → 다시 밝아짐(reverse)
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
      _moodTransitionController.reverse();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _startIntroAnimation();
      });
    });
  }

  void _generateDefaultBoard() {
    final rng = Random(56);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final placedRects = <Rect>[];
    final newCards = <BoardCard>[];
    const centerImgPath = 'imgs/Manifestation/manifestation_21.jpg';
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
            fontFamily: 'monospace',
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
      if (background.imageAsset != null)
        return Image.asset(background.imageAsset!, fit: BoxFit.cover);
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

  Widget _buildGameHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: _theme.deviceBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 나사
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _theme.buttonBg,
              shape: BoxShape.circle,
              border: Border.all(color: _theme.buttonBorder),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'VISION BOARD',
            style: TextStyle(
              color: _theme.accent,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          // 선택된 카드 있으면 "SELECTED" 표시
          if (selectedIndex != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _theme.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _theme.accent),
              ),
              child: Text(
                '▶ CARD ${selectedIndex! + 1}',
                style: TextStyle(
                  color: _theme.accent,
                  fontSize: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _theme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _theme.accent.withOpacity(0.4)),
            ),
            child: Text(
              moodLabels[_currentMood] ?? '',
              style: TextStyle(
                color: _theme.accent,
                fontSize: 8,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          // LED 깜빡임 - 파티클 색상과 연동, 저장 시 빠르게 깜빡임
          AnimatedBuilder(
            animation: Listenable.merge([
              _neonController,
              _savePulseController,
            ]),
            builder: (_, __) {
              final ledColor =
                  particleConfigs[_currentMood]?.color ?? _theme.accent;
              // 저장 펄스가 진행 중이면 빠른 깜빡임을 덧씌움
              final saveBlink = _savePulseController.isAnimating
                  ? (sin(_savePulseController.value * pi * 10) + 1) / 2
                  : 0.0;
              final glowStrength =
                  (0.4 + _neonController.value * 0.4 + saveBlink * 0.5).clamp(
                    0.0,
                    1.0,
                  );
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ledColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ledColor.withOpacity(glowStrength),
                      blurRadius: 6 + saveBlink * 6,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _theme.buttonBg,
              shape: BoxShape.circle,
              border: Border.all(color: _theme.buttonBorder),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _theme.buttonBg,
              shape: BoxShape.circle,
              border: Border.all(color: _theme.buttonBorder),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameButtons() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: _theme.deviceBg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 무드 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final entry in moodLabels.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GameButton3D(
                    label: entry.value,
                    width: 72,
                    height: 26,
                    isActive: _currentMood == entry.key,
                    theme: _theme,
                    fontSize: 7,
                    onTap: () => _applyMood(entry.key),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 하단 컨트롤
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ★ 3D D-PAD - 선택된 카드 이동
              _build3DDPad(),
              // 중앙 액션 버튼
              Row(
                children: [
                  GameButton3D(
                    label: 'UPLOAD',
                    onTap: _pickImage,
                    width: 58,
                    height: 28,
                    theme: _theme,
                  ),
                  const SizedBox(width: 5),
                  GameButton3D(
                    label: 'TEXT',
                    onTap: () => _showTextDialog(),
                    width: 46,
                    height: 28,
                    theme: _theme,
                  ),
                  const SizedBox(width: 5),
                  GameButton3D(
                    label: 'BG',
                    onTap: _showBgDialog,
                    width: 36,
                    height: 28,
                    theme: _theme,
                  ),
                ],
              ),
              // 오른쪽 버튼
              Row(
                children: [
                  GameButton3D(
                    label: 'SAVE',
                    onTap: () async {
                      await _saveBoard();
                      _savePulseController.forward(from: 0);
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Saved! ✨',
                              style: TextStyle(color: _theme.accent),
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: _theme.deviceBg,
                          ),
                        );
                    },
                    width: 46,
                    height: 28,
                    theme: _theme,
                  ),
                  const SizedBox(width: 5),
                  _isExporting
                      ? SizedBox(
                          width: 46,
                          height: 28,
                          child: Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _theme.accent,
                              ),
                            ),
                          ),
                        )
                      : GameButton3D(
                          label: '↗ PNG',
                          onTap: _exportAsPng,
                          width: 50,
                          height: 28,
                          theme: _theme,
                        ),
                  const SizedBox(width: 5),
                  GameButton3D(
                    label: 'RST',
                    onTap: _confirmReset,
                    width: 36,
                    height: 28,
                    theme: _theme,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ★ 3D D-PAD 빌드
  Widget _build3DDPad() {
    const moveStep = 0.018;
    return SizedBox(
      width: 80,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 가로 바
          Positioned(
            top: 22,
            left: 0,
            child: Container(
              width: 80,
              height: 26,
              decoration: BoxDecoration(
                color: _theme.buttonBg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _theme.buttonBorder),
                boxShadow: [
                  BoxShadow(
                    color: _theme.buttonSide,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          // 세로 바
          Positioned(
            left: 27,
            top: 0,
            child: Container(
              width: 26,
              height: 70,
              decoration: BoxDecoration(
                color: _theme.buttonBg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _theme.buttonBorder),
                boxShadow: [
                  BoxShadow(
                    color: _theme.buttonSide,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          // 중앙
          Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _theme.buttonTop,
                border: Border.all(color: _theme.buttonBorder),
              ),
            ),
          ),
          // 방향 버튼들
          Positioned(
            top: 0,
            left: 28,
            child: DPadButton3D(
              icon: Icons.keyboard_arrow_up,
              theme: _theme,
              onTap: () => _moveSelectedCard(0, -moveStep),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 28,
            child: DPadButton3D(
              icon: Icons.keyboard_arrow_down,
              theme: _theme,
              onTap: () => _moveSelectedCard(0, moveStep),
            ),
          ),
          Positioned(
            left: 0,
            top: 23,
            child: DPadButton3D(
              icon: Icons.keyboard_arrow_left,
              theme: _theme,
              onTap: () => _moveSelectedCard(-moveStep, 0),
            ),
          ),
          Positioned(
            right: 0,
            top: 23,
            child: DPadButton3D(
              icon: Icons.keyboard_arrow_right,
              theme: _theme,
              onTap: () => _moveSelectedCard(moveStep, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenBezel({required Widget child}) {
    return AnimatedBuilder(
      animation: _savePulseController,
      builder: (context, _) {
        // ★ 저장 시 베젤 가장자리가 무드 색상으로 잠깐 펄스
        final pulse = (sin(
          _savePulseController.value * pi,
        )).clamp(0.0, 1.0); // 0→1→0
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: _theme.deviceBorder,
            border: Border.all(color: _theme.screenBorder, width: 2),
            boxShadow: pulse > 0.01
                ? [
                    BoxShadow(
                      color: _theme.accent.withOpacity(pulse * 0.7),
                      blurRadius: 18 + pulse * 14,
                      spreadRadius: 1 + pulse * 2,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(3),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return Scaffold(
        backgroundColor: _theme.deviceBg,
        body: Center(child: CircularProgressIndicator(color: _theme.accent)),
      );

    return Scaffold(
      backgroundColor: _theme.deviceBg,
      body: Column(
        children: [
          _buildGameHeader(),
          Expanded(
            child: _buildScreenBezel(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenW = constraints.maxWidth;
                  final screenH = constraints.maxHeight;
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
                                Positioned.fill(child: _buildBackground()),
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
                                            (iv['opacity']! as double).clamp(
                                              0.0,
                                              1.0,
                                            );
                                        final scale = (iv['scale']! as double)
                                            .clamp(0.0, 1.5);
                                        final introDx = iv['dx']! as double;
                                        final introDy = iv['dy']! as double;
                                        final introRotate =
                                            iv['rotate']! as double;
                                        final floatBlend = introOpacity.clamp(
                                          0.0,
                                          1.0,
                                        );
                                        final floatY = isSelected
                                            ? 0.0
                                            : sin(
                                                    _floatController.value *
                                                            pi +
                                                        floatOffset,
                                                  ) *
                                                  _floatAmplitude *
                                                  floatBlend;
                                        final floatRot = isSelected
                                            ? 0.0
                                            : sin(
                                                    _floatController.value *
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
                                                        _neonController.value *
                                                                pi *
                                                                2 +
                                                            floatOffset,
                                                      ) *
                                                      (1.0 - _neonIntensityBase)
                                            : 1.0;

                                        // ★ 스포트라이트: 선택 안 된 카드 어둡게
                                        final dimOpacity = selectedIndex != null
                                            ? (isSelected
                                                  ? 1.0
                                                  : (1.0 - spotlightVal * 0.65))
                                            : 1.0;

                                        // ★ 선택된 카드 확대 - 펄스(바운스) 효과
                                        final selectCurve = Curves.elasticOut
                                            .transform(
                                              _selectScaleController.value,
                                            );
                                        final selectScale = isSelected
                                            ? (1.0 + selectCurve * 0.1)
                                            : 1.0;

                                        // ★ 드래그 중인 카드 들어올리기 효과
                                        final isDragging =
                                            draggingIndex == index;
                                        final dragScale = isDragging
                                            ? 1.22
                                            : 1.0;

                                        // ★ 새로 추가된 카드 - 슬롯에서 톡 튀어나오는 등장 효과
                                        final isSpawning = spawnIndex == index;
                                        final spawnT = Curves.elasticOut
                                            .transform(
                                              _spawnController.value.clamp(
                                                0.0,
                                                1.0,
                                              ),
                                            );
                                        final spawnScale = isSpawning
                                            ? (0.05 + spawnT * 0.95)
                                            : 1.0;
                                        final spawnOpacity = isSpawning
                                            ? _spawnController.value.clamp(
                                                0.0,
                                                1.0,
                                              )
                                            : 1.0;
                                        final spawnRiseY = isSpawning
                                            ? (1.0 -
                                                      _spawnController.value
                                                          .clamp(0.0, 1.0)) *
                                                  60.0
                                            : 0.0;

                                        // ★ 드래그 시 카드가 살짝 위로 들리는 느낌
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
                                            behavior: HitTestBehavior.opaque,
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
                                            onPanEnd: (_) {
                                              setState(
                                                () => draggingIndex = null,
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
                                                  duration: const Duration(
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
                                                              blurRadius: 30,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    18,
                                                                  ),
                                                              spreadRadius: 2,
                                                            ),
                                                          ]
                                                        : [],
                                                  ),
                                                  child: Transform.rotate(
                                                    angle:
                                                        introRotate + floatRot,
                                                    child: Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        // ★ 선택 시 카드 주변 글로우 테두리
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
                                                                    color: _theme
                                                                        .accent
                                                                        .withOpacity(
                                                                          0.6 *
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
                                                                  width: 2,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        // 카드 본체
                                                        card.imageUrl != null ||
                                                                card.imageBase64 !=
                                                                    null
                                                            ? _buildPhotoCard(
                                                                card,
                                                                pw,
                                                                ph,
                                                              )
                                                            : _buildSpecialTextCard(
                                                                text:
                                                                    card.text!,
                                                                style:
                                                                    card.style,
                                                                textColor: Color(
                                                                  card.textColor,
                                                                ),
                                                                paperColor: Color(
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
                                // ★ 반짝이는 파티클 레이어 (카드 위, 무드별 스타일)
                                Positioned.fill(
                                  child: ParticleOverlay(mood: _currentMood),
                                ),
                                // ★ 무드 전환 트랜지션 (카트리지 교체 느낌: 암전 + 스캔라인)
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _moodTransitionController,
                                    builder: (context, _) => IgnorePointer(
                                      child: CustomPaint(
                                        painter: MoodTransitionPainter(
                                          t: _moodTransitionController.value,
                                          color: _theme.accent,
                                        ),
                                        size: Size.infinite,
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          _buildGameButtons(),
        ],
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
                    fontFamily: 'monospace',
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
                              fontFamily: 'monospace',
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
                              fontFamily: 'monospace',
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
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 160,
                          height: 200,
                          color: _theme.screenBg,
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
                          fontFamily: 'monospace',
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
                      fontFamily: 'monospace',
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
                              fontFamily: 'monospace',
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
                      fontFamily: 'monospace',
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
                                fontFamily: 'monospace',
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
                      fontFamily: 'monospace',
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
                      fontFamily: 'monospace',
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
                            fontFamily: 'monospace',
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
}

// ★ 무드 전환 시 카트리지 교체 느낌 - 암전 + 스캔라인
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

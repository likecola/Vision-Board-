import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'web_synth.dart';

// ─────────────────────────────────────────────────────────────
// 비전보드 인트로 (INTRO_SPEC.md 구현)
//
// IDLE → CARTRIDGE → POWER ON → BOOT LOG → LOGO DING → HELLO → (진단 시작)
// HELLO 단계는 "타임라인 종료 AND 앱 로딩 완료"가 둘 다 만족될 때만 진입한다.
// ─────────────────────────────────────────────────────────────

const _kPageDark = Color(0xFF0B0717);
const _kPageLight = Color(0xFF24123F);
const _kViolet = Color(0xFFCF8BFF);
const _kPink = Color(0xFFFF79C6);
const _kInk = Color(0xFF2A1450);
const _kScreenBg = Color(0xFF07050D);
const _kBezel = Color(0xFF0C0720);
const _kMuted = Color(0xFF9B85C7);
const _kMuted2 = Color(0xFF6F5A96);
const _kText = Color(0xFFE9D8FF);
const _kGreen = Color(0xFF7DFFB0);
const _kBubbleBg = Color(0xFFFFF6E0);

// 디자인 기준 크기 (뷰포트가 작으면 FittedBox가 비율 유지로 축소)
const double _kShellTop = 150;

TextStyle _ps(
  double size,
  Color color, {
  double ls = 0,
  List<Shadow>? shadows,
}) => TextStyle(
  fontFamily: 'PressStart2P',
  fontSize: size,
  color: color,
  letterSpacing: ls,
  shadows: shadows,
  decoration: TextDecoration.none,
);

TextStyle _vt(double size, Color color, {double height = 1.1}) => TextStyle(
  fontFamily: 'VT323',
  fontSize: size,
  color: color,
  height: height,
  decoration: TextDecoration.none,
);

TextStyle _jua(double size, Color color, {double height = 1.2}) => TextStyle(
  fontFamily: 'Jua',
  fontSize: size,
  color: color,
  height: height,
  decoration: TextDecoration.none,
);

TextStyle _mono(double size, Color color, {double ls = 0, bool bold = false}) =>
    TextStyle(
      fontFamily: 'SpaceMono',
      fontSize: size,
      color: color,
      letterSpacing: ls,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      decoration: TextDecoration.none,
    );

enum IntroPhase { idle, rise, insert, power, boot, logo, ready, done }

enum _LogoPos { hidden, start, center, top }

class IntroOverlay extends StatefulWidget {
  const IntroOverlay({
    super.key,
    required this.appReady,
    required this.onStartDiagnosis,
    required this.onFinished,
    this.allowSkip = false,
    this.speed = 1.0,
    this.onStarted,
  });

  /// 앱(보드) 로딩이 끝나면 true. HELLO 단계 진입 조건.
  final ValueListenable<bool> appReady;

  /// A 버튼(진단 시작) — 진단 화면을 앱 쪽에서 열어달라는 신호.
  final VoidCallback onStartDiagnosis;

  /// 페이드아웃까지 끝나 오버레이를 제거해도 될 때.
  final VoidCallback onFinished;

  /// 재방문자에게만 SKIP(▸▸) 버튼과 S 키를 허용한다.
  final bool allowSkip;

  /// 모든 타이밍 배율 (0.5~2).
  final double speed;

  /// 첫 클릭(PRESS START) 시점 — 재방문 판정 저장용.
  final VoidCallback? onStarted;

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay>
    with TickerProviderStateMixin {
  static const _lines = <({String t, String s, String b})>[
    (t: 'DREAM OS v6.0   (c) 2026 VISION LAB', s: '', b: '으음… 여기 어디?'),
    (t: '> mounting cartridge DREAMS.GB ...', s: 'ok', b: '카트리지 확인!'),
    (t: '> loading dreams .................', s: 'ok', b: '꿈 불러오는 중…'),
    (t: '> calibrating vibes ..............', s: 'ok', b: '바이브 맞추는 중 ♪'),
    (t: '> polishing stars ................', s: 'ok', b: '반짝반짝 ✦'),
    (t: '> waking up mascot ...............', s: 'ok', b: '다 깼다!'),
  ];

  final _synth = WebSynth.instance;
  final _focus = FocusNode(debugLabel: 'intro');

  // 시간 기반 상시 애니메이션(LED, 깜빡임, 바운스…)용 시계
  late final AnimationController _clock;
  late final AnimationController _rise; // 카트리지 상승 1.0s
  late final AnimationController _insert; // 슬롯 삽입 0.26s
  late final AnimationController _shake; // 딸깍 셸 흔들림 0.26s
  late final AnimationController _crt; // CRT 켜짐 0.56s
  late final AnimationController _logoDrop; // 로고 낙하 1.6s linear
  late final AnimationController _logoTop; // 로고 상단 이동 0.6s
  late final AnimationController _flash; // 로고 밝기 플래시 0.52s
  late final AnimationController _fadeOut; // 인트로 종료 페이드

  // 휴대폰 세로면 세로형 콘솔(좁고 길게), 아니면 가로형 콘솔로 그린다.
  bool _portrait = false;
  double get _dw => _portrait ? 400 : 960;
  double get _dh => _portrait ? 880 : 800;
  double get _shellApproxH => _portrait ? 700 : 640;
  double get _screenH => _portrait ? 420 : 400;

  IntroPhase _phase = IntroPhase.idle;
  _LogoPos _logoPos = _LogoPos.hidden;
  int _lineIdx = -1;
  int _charIdx = 0;
  int _okCount = 0;
  String _bubble = '';
  bool _timelineEnded = false;

  final _timers = <Timer>[];
  final _intervals = <Timer>[];

  double get _sp => widget.speed > 0 ? widget.speed : 1.0;

  Duration _ms(num ms) => Duration(microseconds: (ms * 1000 / _sp).round());

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..repeat();
    _rise = AnimationController(vsync: this, duration: _ms(1000));
    _insert = AnimationController(vsync: this, duration: _ms(260));
    _shake = AnimationController(vsync: this, duration: _ms(260));
    _crt = AnimationController(vsync: this, duration: _ms(560));
    _logoDrop = AnimationController(vsync: this, duration: _ms(1600));
    _logoTop = AnimationController(vsync: this, duration: _ms(600));
    _flash = AnimationController(vsync: this, duration: _ms(520));
    _fadeOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    widget.appReady.addListener(_maybeReady);
  }

  @override
  void dispose() {
    widget.appReady.removeListener(_maybeReady);
    _clearAll();
    for (final c in [
      _clock,
      _rise,
      _insert,
      _shake,
      _crt,
      _logoDrop,
      _logoTop,
      _flash,
      _fadeOut,
    ]) {
      c.dispose();
    }
    _focus.dispose();
    super.dispose();
  }

  // ── 타이머 ──
  void _after(num ms, VoidCallback fn) {
    _timers.add(
      Timer(_ms(ms), () {
        if (mounted) fn();
      }),
    );
  }

  void _clearAll() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final t in _intervals) {
      t.cancel();
    }
    _timers.clear();
    _intervals.clear();
  }

  // ── 시퀀스 ──
  void _press() {
    if (_phase != IntroPhase.idle) return;
    widget.onStarted?.call();
    _synth.boot();
    setState(() => _phase = IntroPhase.rise);
    _rise.forward(from: 0);
    _after(1000, () {
      setState(() => _phase = IntroPhase.insert);
      _insert.forward(from: 0);
    });
    _after(1260, () {
      _synth.clack();
      _shake.forward(from: 0);
    });
    _after(1650, () {
      setState(() => _phase = IntroPhase.power);
      _synth.power();
      _crt.forward(from: 0);
    });
    _after(2150, () {
      setState(() => _phase = IntroPhase.boot);
      _typeLine(0);
    });
  }

  void _typeLine(int i) {
    if (i >= _lines.length) {
      _after(380, _toLogo);
      return;
    }
    final l = _lines[i];
    setState(() {
      _lineIdx = i;
      _charIdx = 0;
      _bubble = l.b;
    });
    var c = 0;
    final iv = Timer.periodic(Duration(microseconds: (20000 / _sp).round()), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      c = min(l.t.length, c + 2);
      setState(() => _charIdx = c);
      if (c % 6 == 0) _synth.typeTick();
      if (c >= l.t.length) {
        timer.cancel();
        _after(150, () {
          if (l.s.isNotEmpty) _synth.ok();
          setState(() => _okCount = i + 1);
          _after(200, () => _typeLine(i + 1));
        });
      }
    });
    _intervals.add(iv);
  }

  void _toLogo() {
    setState(() {
      _phase = IntroPhase.logo;
      _logoPos = _LogoPos.start;
    });
    _after(40, () {
      setState(() => _logoPos = _LogoPos.center);
      _logoDrop.forward(from: 0);
    });
    _after(1750, () {
      _synth.logoDing();
      _flash.forward(from: 0);
    });
    _after(2600, () {
      _timelineEnded = true;
      _maybeReady();
    });
  }

  /// HELLO 진입 게이트: 타임라인 종료 AND 앱 로딩 완료.
  void _maybeReady() {
    if (!mounted) return;
    if (_phase != IntroPhase.logo) return;
    if (!_timelineEnded || !widget.appReady.value) return;
    setState(() {
      _phase = IntroPhase.ready;
      _logoPos = _LogoPos.top;
    });
    _logoTop.forward(from: 0);
  }

  void _skip() {
    if (!widget.allowSkip) return;
    if (_phase == IntroPhase.ready || _phase == IntroPhase.done) return;
    final wasIdle = _phase == IntroPhase.idle;
    if (wasIdle) widget.onStarted?.call();
    _clearAll();
    _rise.value = 1;
    _insert.value = 1;
    _crt.value = 1;
    _logoDrop.value = 1;
    setState(() {
      _phase = IntroPhase.logo;
      _logoPos = _LogoPos.center;
      _lineIdx = _lines.length - 1;
      _okCount = _lines.length;
      _timelineEnded = true;
    });
    _maybeReady();
  }

  void _pressA() {
    if (_phase == IntroPhase.idle) {
      _press();
      return;
    }
    if (_phase != IntroPhase.ready) {
      _synth.blip();
      return;
    }
    _synth.startDiagnosis();
    setState(() => _phase = IntroPhase.done);
    widget.onStartDiagnosis();
    _fadeOut.forward(from: 0).then((_) {
      if (mounted) widget.onFinished();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
      _phase == IntroPhase.ready ? _pressA() : _press();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyS) {
      _skip();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── 상시 애니메이션 헬퍼 (t = 경과 초) ──
  double _wave(double t, double period, {double delay = 0}) {
    if (t < delay) return 0;
    final p = ((t - delay) % period) / period;
    return (1 - cos(2 * pi * p)) / 2; // 0→1→0 (ease-in-out)
  }

  bool _eyesClosed(double t) => t >= 2.6 && (t % 2.6) < 0.15;

  // ─────────────────────────────────────────────
  // build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(_fadeOut),
      child: Material(
        color: _kPageDark,
        child: Focus(
          autofocus: true,
          focusNode: _focus,
          onKeyEvent: _onKey,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focus.requestFocus,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1),
                  radius: 1.25,
                  colors: [_kPageLight, _kPageDark],
                  stops: [0, 0.65],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        _portrait =
                            box.maxWidth < 700 ||
                            box.maxWidth < box.maxHeight * 0.95;
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: _dw,
                            height: _dh,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _clock,
                                _rise,
                                _insert,
                                _shake,
                                _crt,
                                _logoDrop,
                                _logoTop,
                                _flash,
                              ]),
                              builder: (context, _) => _buildConsole(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.allowSkip &&
                      _phase != IntroPhase.ready &&
                      _phase != IntroPhase.done)
                    Positioned(
                      top: 18,
                      right: 24,
                      child: _SkipButton(onTap: _skip),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _on => const {
    IntroPhase.power,
    IntroPhase.boot,
    IntroPhase.logo,
    IntroPhase.ready,
    IntroPhase.done,
  }.contains(_phase);

  bool get _inserted => _phase != IntroPhase.idle && _phase != IntroPhase.rise;

  Widget _buildConsole() {
    final t = _clock.value * 3600.0;
    final cart = _buildCartridge();
    final shake = _shakeOffset();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_inserted && cart != null) cart, // 삽입 후: 셸 뒤
        Positioned(
          top: _kShellTop,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, shake),
            child: _buildShell(t),
          ),
        ),
        if (!_inserted && cart != null) cart, // 상승 중: 셸 앞
      ],
    );
  }

  double _shakeOffset() {
    if (!_shake.isAnimating) return 0;
    final v = _shake.value;
    // 0 → 5 → -2 → 0
    if (v < 1 / 3) return 5 * Curves.easeOut.transform(v * 3);
    if (v < 2 / 3) return 5 + (-7) * Curves.easeOut.transform((v - 1 / 3) * 3);
    return -2 + 2 * Curves.easeOut.transform((v - 2 / 3) * 3);
  }

  // ── 카트리지 ──
  Widget? _buildCartridge() {
    if (_phase == IntroPhase.idle) return null;
    double topRel, rot, scale, opacity = 1, glow;
    if (!_inserted) {
      final v = _rise.value;
      final e = const Cubic(.16, .84, .26, 1).transform(v);
      topRel = lerpDouble(_shellApproxH + 60, -118, e);
      rot = lerpDouble(10, -5, e) * pi / 180;
      scale = lerpDouble(.9, 1.1, e);
      opacity = min(1.0, v * 1000 / 250);
      glow = 1;
    } else {
      final v = _insert.value;
      final e = const Cubic(.6, 0, .9, .4).transform(v);
      topRel = lerpDouble(-118, -62, e);
      rot = lerpDouble(-5, 0, e) * pi / 180;
      scale = lerpDouble(1.1, 1, e);
      glow = 1 - e;
    }
    return Positioned(
      left: (_dw - 150) / 2,
      top: _kShellTop + topRel,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(rot)
            ..scaleByDouble(scale, scale, 1, 1),
          child: _Cartridge(
            glow: glow,
            sweep: _wave(_clock.value * 3600.0, 1.6),
          ),
        ),
      ),
    );
  }

  // ── 셸 ──
  Widget _buildShell(double t) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment(-0.03, -1),
          end: Alignment(0.03, 1),
          colors: [Color(0xFF4E2F86), Color(0xFF3A2566), Color(0xFF1D1138)],
          stops: [0, 0.14, 1],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x1AFFFFFF), offset: Offset(0, 2)),
          BoxShadow(
            color: Color(0x8C000000),
            offset: Offset(0, 40),
            blurRadius: 80,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x1AFFFFFF),
                      Color(0x00FFFFFF),
                      Color(0x00000000),
                      Color(0x2E000000),
                    ],
                    stops: [0, .22, .8, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 168,
                height: 9,
                decoration: const BoxDecoration(
                  color: _kBezel,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildHeader(), _buildBezel(t), _buildControls(t)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Pressable(
            label: 'POWER switch',
            onTap: _press,
            builder: (_) => Row(
              children: [
                Container(
                  width: 42,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _kBezel,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.ease,
                        top: 2,
                        left: _phase == IntroPhase.idle ? 2 : 26,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _phase == IntroPhase.idle
                                ? _kMuted
                                : _kGreen,
                            boxShadow: _phase == IntroPhase.idle
                                ? null
                                : const [
                                    BoxShadow(color: _kGreen, blurRadius: 8),
                                  ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_portrait) ...[
                  const SizedBox(width: 10),
                  Text('OFF · ON', style: _mono(9, _kMuted, ls: 2)),
                ],
              ],
            ),
          ),
          Text(
            'DREAM OS',
            style: _ps(_portrait ? 10 : 12, const Color(0x38FFFFFF), ls: 2),
          ),
          SizedBox(
            width: _portrait ? 112 : 150,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'CART · ', style: _mono(10, _kMuted, ls: 1)),
                  TextSpan(
                    text: _inserted ? 'DREAMS.GB' : '— —',
                    style: _mono(10, _kText, ls: 1, bold: true),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBezel(double t) {
    final ledOn = _on;
    final ledBlink = 0.25 + 0.75 * (1 - _wave(t, 1.4));
    return Container(
      decoration: const BoxDecoration(
        color: _kBezel,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(46),
          bottomLeft: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0FFFFFFF),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: _portrait
                ? const EdgeInsets.fromLTRB(12, 28, 12, 14)
                : const EdgeInsets.fromLTRB(18, 22, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _portrait
                  ? [Expanded(child: _buildScreen(t))]
                  : [
                      SizedBox(
                        width: 52,
                        height: _screenH,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: ledOn ? 1 : ledBlink,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ledOn
                                      ? _kGreen
                                      : const Color(0xFFFF4D6D),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ledOn
                                          ? _kGreen
                                          : const Color(0xFFFF4D6D),
                                      blurRadius: ledOn ? 10 : 10 * ledBlink,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('POWER', style: _mono(7, _kMuted2, ls: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: _buildScreen(t)),
                      const SizedBox(width: 14),
                      const SizedBox(width: 52),
                    ],
            ),
          ),
          if (_portrait)
            Positioned(
              top: 8,
              left: 16,
              child: Row(
                children: [
                  Opacity(
                    opacity: ledOn ? 1 : ledBlink,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ledOn ? _kGreen : const Color(0xFFFF4D6D),
                        boxShadow: [
                          BoxShadow(
                            color: ledOn ? _kGreen : const Color(0xFFFF4D6D),
                            blurRadius: ledOn ? 8 : 8 * ledBlink,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('POWER', style: _mono(7, _kMuted2, ls: 1.5)),
                ],
              ),
            ),
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'DREAM MATRIX WITH STEREO VIBES',
                style: _mono(
                  _portrait ? 6 : 8,
                  _kMuted2,
                  ls: _portrait ? 1 : 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 화면 ──
  Widget _buildScreen(double t) {
    return Semantics(
      button: _phase == IntroPhase.idle,
      label: _phase == IntroPhase.idle ? 'PRESS START' : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_phase == IntroPhase.idle) _press();
        },
        child: MouseRegion(
          cursor: _phase == IntroPhase.idle
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Container(
            height: _screenH,
            decoration: BoxDecoration(
              color: _kScreenBg,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0xB3000000), spreadRadius: 2),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _on ? 1 : 0,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(-0.4, -0.7),
                            radius: 1.2,
                            colors: [
                              Color(0xFF4A256F),
                              Color(0xFF2A1450),
                              Color(0xFF150A30),
                            ],
                            stops: [0, .45, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(child: _Scanlines()),
                  ),
                  if (_phase == IntroPhase.idle) _buildIdle(t),
                  if (_phase == IntroPhase.boot) _buildBootLog(box.maxWidth),
                  if (_phase == IntroPhase.boot && _lineIdx >= 0)
                    _buildBootMascot(t),
                  _buildLogo(box.maxHeight),
                  if (_phase == IntroPhase.logo &&
                      _timelineEnded &&
                      !widget.appReady.value)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 36,
                      child: Center(
                        child: Opacity(
                          opacity: (t % 0.9) < 0.45 ? 1 : 0.25,
                          child: Text('LOADING...', style: _vt(22, _kViolet)),
                        ),
                      ),
                    ),
                  if (_phase == IntroPhase.ready || _phase == IntroPhase.done)
                    _buildReady(t, box.maxHeight),
                  _buildCrt(),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: box.maxHeight * 0.4,
                    child: const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x12FFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCrt() {
    if (!_crt.isAnimating) return const SizedBox.shrink();
    final v = _crt.value;
    double sx, sy, op;
    if (v < .35) {
      sx = Curves.easeOut.transform(v / .35);
      sy = .006;
      op = 1;
    } else if (v < .7) {
      final p = Curves.easeOut.transform((v - .35) / .35);
      sx = 1;
      sy = lerpDouble(.006, 1, p);
      op = lerpDouble(1, .85, p);
    } else {
      sx = 1;
      sy = 1;
      op = lerpDouble(.85, 0, Curves.easeOut.transform((v - .7) / .3));
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: op.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(max(sx, 0.0001), sy, 1),
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildIdle(double t) {
    final zs = [
      (size: 9.0, ch: 'z', delay: 0.0),
      (size: 12.0, ch: 'z', delay: 0.8),
      (size: 15.0, ch: 'Z', delay: 1.6),
    ];
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: .45,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Mascot(px: 5, closed: true),
                Positioned(
                  top: -6,
                  right: -26,
                  child: Row(
                    children: [
                      for (final z in zs) _zChar(t, z.size, z.ch, z.delay),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Opacity(
            opacity: (t % 1.1) < .55 ? 1 : 0,
            child: Text(
              'PRESS START',
              style: _ps(
                _portrait ? 17 : 22,
                _kViolet,
                ls: _portrait ? 2 : 3,
                shadows: const [
                  Shadow(color: Color(0x99CF8BFF), blurRadius: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'START 버튼이나 화면을 눌러 스텔라를 깨워주세요',
              textAlign: TextAlign.center,
              style: _jua(_portrait ? 13 : 15, const Color(0xFF8E78B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zChar(double t, double size, String ch, double delay) {
    double p = 0;
    if (t >= delay) p = ((t - delay) % 2.4) / 2.4;
    final op = p < .3 ? p / .3 : 1 - (p - .3) / .7;
    final scale = lerpDouble(.7, 1.2, p);
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Opacity(
        opacity: t < delay ? 0 : op.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(14 * p, -30 * p),
          child: Transform.scale(
            scale: scale,
            child: Text(ch, style: _ps(size, _kMuted)),
          ),
        ),
      ),
    );
  }

  Widget _buildBootLog(double screenW) {
    final total = _lines.length;
    final lines = <Widget>[];
    for (var i = 0; i <= _lineIdx && i < total; i++) {
      final l = _lines[i];
      final cur = i == _lineIdx;
      final text = cur ? l.t.substring(0, _charIdx) : l.t;
      final cursor = cur && _charIdx < l.t.length;
      final ok = _okCount > i && l.s.isNotEmpty;
      lines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              Text(
                text,
                style: _vt(_portrait ? 19 : 24, _kText),
                softWrap: false,
              ),
              if (cursor) ...[
                const SizedBox(width: 10),
                Opacity(
                  opacity: (_clock.value * 3600 % 0.6) < .3 ? 1 : 0,
                  child: Text('█', style: _vt(_portrait ? 19 : 24, _kViolet)),
                ),
              ],
              if (ok) ...[
                const SizedBox(width: 10),
                Text(l.s, style: _vt(_portrait ? 19 : 24, _kGreen)),
              ],
            ],
          ),
        ),
      );
    }
    final curLen = (_lineIdx >= 0 && _lineIdx < total)
        ? _lines[_lineIdx].t.length
        : 1;
    final prog = min(
      1.0,
      (max(0, _lineIdx) + min(1.0, _charIdx / curLen)) / total,
    );
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _portrait ? 16 : 32,
          vertical: _portrait ? 16 : 26,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines,
            ),
            FractionallySizedBox(
              widthFactor: _portrait ? .96 : .62,
              alignment: Alignment.centerLeft,
              child: _LoadingBar(progress: prog),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBootMascot(double t) {
    final bob = -7 * _wave(t, 1.1);
    return Positioned(
      right: _portrait ? 12 : 30,
      bottom: _portrait ? 54 : 24,
      child: _Pop(
        key: const ValueKey('bootMascot'),
        duration: const Duration(milliseconds: 400),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: _portrait ? 34 : 46),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kBubbleBg,
                border: Border.all(color: _kInk, width: 3),
              ),
              child: Text(
                _bubble,
                style: _jua(_portrait ? 13 : 15, _kInk),
                softWrap: false,
              ),
            ),
            const SizedBox(width: 10),
            Transform.translate(
              offset: Offset(0, bob),
              child: Mascot(px: _portrait ? 4 : 5, closed: _eyesClosed(t)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(double screenH) {
    if (_logoPos == _LogoPos.hidden) return const SizedBox.shrink();
    double frac;
    double scale = 1;
    switch (_logoPos) {
      case _LogoPos.start:
        frac = -.2;
      case _LogoPos.center:
        frac = lerpDouble(-.2, .46, _logoDrop.value); // linear
      case _LogoPos.top:
        final e = const Cubic(.2, .9, .2, 1).transform(_logoTop.value);
        frac = lerpDouble(.46, .16, e);
        scale = lerpDouble(1, .55, e);
      case _LogoPos.hidden:
        frac = -.2;
    }
    final b = _flash.isAnimating ? 1 + sin(pi * _flash.value) : 1.0;
    final logo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DREAM OS',
          style: _ps(
            _portrait ? 30 : 40,
            _kViolet,
            ls: _portrait ? 3 : 4,
            shadows: [
              const Shadow(color: _kInk, offset: Offset(4, 4)),
              const Shadow(color: Color(0x80CF8BFF), blurRadius: 30),
              if (b > 1) Shadow(color: _kViolet, blurRadius: 24 * (b - 1)),
            ],
          ),
          softWrap: false,
        ),
        const SizedBox(height: 14),
        Text(
          'VER 6 ✦ VISION BOARD',
          style: _ps(_portrait ? 8 : 10, _kPink, ls: _portrait ? 2 : 3),
          softWrap: false,
        ),
      ],
    );
    return Positioned(
      left: 0,
      right: 0,
      top: screenH * frac,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(0, -0.5),
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  b, 0, 0, 0, 0, //
                  0, b, 0, 0, 0, //
                  0, 0, b, 0, 0, //
                  0, 0, 0, 1, 0,
                ]),
                child: logo,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReady(double t, double screenH) {
    final done = _phase == IntroPhase.done;
    final bob = -7 * _wave(t, 1.3);
    final pulse = _wave(t, 1.2);
    return Positioned(
      left: 0,
      right: 0,
      top: screenH * (_portrait ? .2 : .3),
      bottom: 0,
      child: _FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flex(
              direction: _portrait ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, bob),
                  child: Mascot(px: _portrait ? 6 : 7, closed: _eyesClosed(t)),
                ),
                SizedBox(width: _portrait ? 0 : 18, height: _portrait ? 10 : 0),
                _Pop(
                  delay: const Duration(milliseconds: 150),
                  duration: const Duration(milliseconds: 450),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: _portrait ? 280 : 300,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _kBubbleBg,
                      border: Border.all(color: _kInk, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x59000000),
                          offset: Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: _jua(_portrait ? 17 : 20, _kInk, height: 1.4),
                        children: const [
                          TextSpan(text: '안녕! 나는 '),
                          TextSpan(
                            text: '스텔라',
                            style: TextStyle(color: Color(0xFFC2187A)),
                          ),
                          TextSpan(text: ' ✦\n너의 꿈을 진단해볼까?'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Pop(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 450),
              child: _Pressable(
                label: 'A 진단 시작',
                onTap: done ? null : _pressA,
                builder: (pressed) => Container(
                  transform: Matrix4.translationValues(0, pressed ? 4 : 0, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _kPink,
                    border: Border.all(color: _kInk, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _kInk,
                        offset: Offset(0, pressed ? 1 : 5),
                      ),
                      if (!pressed)
                        BoxShadow(
                          color: Color.fromRGBO(255, 121, 198, .75 * pulse),
                          blurRadius: 16 * pulse,
                          spreadRadius: 4 * pulse,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: _kInk,
                          shape: BoxShape.circle,
                        ),
                        child: Text('A', style: _ps(10, _kPink)),
                      ),
                      const SizedBox(width: 10),
                      Text('진단 시작', style: _jua(19, const Color(0xFF1D1138))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 컨트롤 ──
  Widget _buildControls(double t) {
    final idle = _phase == IntroPhase.idle;
    final ready = _phase == IntroPhase.ready;
    final startPulse = idle ? _wave(t, 1.4) : 0.0;
    final aPulse = ready ? _wave(t, 1.2) : 0.0;
    const tilt = -18 * pi / 180;

    final pills = Transform.rotate(
      angle: tilt,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillButton(
            label: 'SELECT',
            color: const Color(0xFF241248),
            textStyle: _mono(9, _kMuted, ls: 2),
            onTap: _synth.blip,
          ),
          const SizedBox(width: 26),
          _pillButton(
            label: 'START',
            color: idle ? _kPink : const Color(0xFF241248),
            textStyle: _mono(9, _kText, ls: 2, bold: true),
            pulse: startPulse,
            onTap: _press,
          ),
        ],
      ),
    );
    final ab = Transform.rotate(
      angle: tilt,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: _roundButton(
              label: 'B',
              top: const Color(0xFFD58CFF),
              bottom: const Color(0xFF8A3FBF),
              edge: const Color(0xFF4A1D6E),
              labelColor: _kMuted,
              onTap: _synth.blip,
            ),
          ),
          const SizedBox(width: 18),
          _roundButton(
            label: 'A',
            top: const Color(0xFFFF9FD6),
            bottom: const Color(0xFFD0388E),
            edge: const Color(0xFF7A1A52),
            labelColor: _kText,
            pulse: aPulse,
            onTap: _pressA,
          ),
        ],
      ),
    );

    if (_portrait) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const _DPad(), ab],
            ),
            const SizedBox(height: 18),
            // D-패드 아래 왼쪽에 둬서 오른쪽 A/B와 겹치지 않게 한다.
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(padding: const EdgeInsets.only(left: 22), child: pills),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 22, 36, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [const _DPad(), pills, ab],
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required Color color,
    required TextStyle textStyle,
    required VoidCallback onTap,
    double pulse = 0,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pressable(
          label: label,
          onTap: onTap,
          builder: (pressed) => Container(
            width: 56,
            height: 16,
            transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF120826),
                  offset: Offset(0, pressed ? 0 : 3),
                ),
                if (pulse > 0 && !pressed)
                  BoxShadow(
                    color: Color.fromRGBO(255, 121, 198, .75 * pulse),
                    blurRadius: 16 * pulse,
                    spreadRadius: 4 * pulse,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: textStyle),
      ],
    );
  }

  Widget _roundButton({
    required String label,
    required Color top,
    required Color bottom,
    required Color edge,
    required Color labelColor,
    required VoidCallback onTap,
    double pulse = 0,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pressable(
          label: '$label button',
          onTap: onTap,
          builder: (pressed) => Container(
            width: 52,
            height: 52,
            transform: Matrix4.translationValues(0, pressed ? 4 : 0, 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-.24, -.36),
                radius: .9,
                colors: [top, bottom],
              ),
              boxShadow: [
                BoxShadow(color: edge, offset: Offset(0, pressed ? 1 : 5)),
                if (!pressed)
                  const BoxShadow(
                    color: Color(0x66000000),
                    offset: Offset(0, 8),
                    blurRadius: 14,
                  ),
                if (pulse > 0 && !pressed)
                  BoxShadow(
                    color: Color.fromRGBO(255, 121, 198, .75 * pulse),
                    blurRadius: 16 * pulse,
                    spreadRadius: 4 * pulse,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: _ps(9, labelColor)),
      ],
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

// ─────────────────────────────────────────────────────────────
// 마스코트 "스텔라" — 15×14 픽셀 아트 (CustomPainter)
// ─────────────────────────────────────────────────────────────
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    required this.px,
    this.closed = false,
    this.costume,
  });

  final double px;
  final bool closed;

  /// 무드별 의상 키 (manifestation / soft_life / that_girl / cyber_dream / wanderlust)
  final String? costume;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 15 * px,
    height: 14 * px,
    child: CustomPaint(
      painter: MascotPainter(px: px, closed: closed, costume: costume),
    ),
  );
}

class MascotPainter extends CustomPainter {
  MascotPainter({required this.px, required this.closed, this.costume});

  final double px;
  final bool closed;
  final String? costume;

  /// 의상: (행, 열) → 팔레트 문자. 몸 밖(음수/범위 밖)에도 그릴 수 있다.
  static const costumes = <String, Map<(int, int), String>>{
    // 왕관 + 보석
    'manifestation': {
      (0, 7): 'C',
      (1, 7): 'C',
      (2, 7): 'C',
      (3, 6): 'C',
      (3, 7): 'C',
      (3, 8): 'C',
      (1, 5): 'W',
      (1, 9): 'W',
    },
    // 새싹 + 잎
    'soft_life': {
      (0, 7): 'G',
      (1, 7): 'G',
      (2, 7): 'G',
      (3, 6): 'G',
      (3, 7): 'G',
      (3, 8): 'G',
      (1, 5): 'G',
      (1, 9): 'G',
      (0, 6): 'R',
      (0, 8): 'R',
    },
    // 선글라스
    'that_girl': {
      (6, 3): 'B',
      (6, 4): 'B',
      (6, 5): 'B',
      (6, 6): 'B',
      (6, 7): 'B',
      (6, 8): 'B',
      (6, 9): 'B',
      (6, 10): 'B',
      (6, 11): 'B',
      (7, 4): 'B',
      (7, 10): 'B',
    },
    // 바이저
    'cyber_dream': {
      (6, 3): 'V',
      (6, 4): 'V',
      (6, 5): 'V',
      (6, 6): 'V',
      (6, 7): 'V',
      (6, 8): 'V',
      (6, 9): 'V',
      (6, 10): 'V',
      (6, 11): 'V',
      (7, 4): 'V',
      (7, 5): 'V',
      (7, 6): 'V',
      (7, 7): 'V',
      (7, 8): 'V',
      (7, 9): 'V',
      (7, 10): 'V',
    },
    // 목도리
    'wanderlust': {
      (9, 4): 'T',
      (9, 5): 'T',
      (9, 6): 'T',
      (9, 7): 'T',
      (9, 8): 'T',
      (9, 9): 'T',
      (9, 10): 'T',
      (10, 5): 'T',
      (10, 6): 'T',
    },
  };

  static const map = [
    '.......K.......',
    '......KYK......',
    '......KYK......',
    '.....KYYYK.....',
    'KKKKKKYYYKKKKKK',
    'KYYWYYYYYYYYYYK',
    '.KYYEYYYYYEYYK.',
    '..KYEYYYYYEYK..',
    '...KPYYMYYPK...',
    '...KYYYYYYYK...',
    '..KYYYYKYYYYK..',
    '..KYYYK.KYYYK..',
    '.KYYK.....KYYK.',
    '.KKK.......KKK.',
  ];

  static const _palette = {
    'K': Color(0xFF2A1450), // 외곽선
    'Y': Color(0xFFFFD84D), // 몸통
    'W': Color(0xFFFFF8D6), // 하이라이트
    'E': Color(0xFF2A1450), // 눈
    'P': Color(0xFFFF8FC8), // 볼터치
    'M': Color(0xFF2A1450), // 입
    'C': Color(0xFFFFB800), // 왕관
    'G': Color(0xFF5BD16F), // 잎
    'R': Color(0xFFFF79C6), // 꽃
    'B': Color(0xFF14101C), // 선글라스
    'V': Color(0xFF2FE6FF), // 바이저
    'T': Color(0xFF52D6C8), // 목도리
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    final over = costumes[costume] ?? const <(int, int), String>{};
    for (var y = 0; y < map.length; y++) {
      final row = map[y];
      for (var x = 0; x < row.length; x++) {
        var ch = row[x];
        if (ch == '.' && !over.containsKey((y, x))) continue;
        // 감은 눈: 6행 E→Y, 7행 E→K
        if (closed && ch == 'E') ch = y == 6 ? 'Y' : 'K';
        ch = over[(y, x)] ?? ch;
        paint.color = _palette[ch]!;
        // 배율 축소 시 셀 사이 틈이 생기지 않도록 아주 조금 겹쳐 그린다.
        canvas.drawRect(
          Rect.fromLTWH(x * px, y * px, px, px).inflate(.3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MascotPainter old) =>
      old.px != px || old.closed != closed || old.costume != costume;
}

// ─────────────────────────────────────────────────────────────
// 카트리지 150×124
// ─────────────────────────────────────────────────────────────
class _CartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width * .86, 0)
    ..lineTo(s.width, s.height * .11)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _CartGlowPainter extends CustomPainter {
  _CartGlowPainter(this.glow);

  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _CartClipper().getClip(size);
    // 떠 있을 때(glow=1)는 크고 부드러운 그림자 + 노란 글로우, 삽입되면 작은 그림자.
    final shadowDy = lerpDouble(6, 14, glow);
    final shadowBlur = lerpDouble(8, 20, glow);
    final shadowAlpha = lerpDouble(.4, .5, glow);
    canvas.drawPath(
      path.shift(Offset(0, shadowDy)),
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, shadowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur / 2),
    );
    if (glow > 0.01) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.fromRGBO(255, 216, 77, .55 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 11),
      );
    }
  }

  @override
  bool shouldRepaint(_CartGlowPainter old) => old.glow != glow;
}

class _Cartridge extends StatelessWidget {
  const _Cartridge({required this.glow, required this.sweep});

  final double glow;
  final double sweep; // 0..1 (하이라이트 쓸고 지나가기)

  @override
  Widget build(BuildContext context) {
    final sx = lerpDouble(-96, 156, Curves.easeInOut.transform(sweep));
    return SizedBox(
      width: 150,
      height: 124,
      child: CustomPaint(
        painter: _CartGlowPainter(glow),
        child: ClipPath(
          clipper: _CartClipper(),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE4DFF0), Color(0xFFB9B0CF)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 14,
                width: 96,
                child: Column(
                  children: [
                    Container(height: 2, color: const Color(0x40281450)),
                    const SizedBox(height: 3),
                    Container(height: 2, color: const Color(0x40281450)),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1138),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const SizedBox(
                          height: 6,
                          child: Row(
                            children: [
                              Expanded(
                                child: ColoredBox(color: Color(0xFFCF8BFF)),
                              ),
                              Expanded(
                                child: ColoredBox(color: Color(0xFFE6D4B6)),
                              ),
                              Expanded(
                                child: ColoredBox(color: Color(0xFFCBA24F)),
                              ),
                              Expanded(
                                child: ColoredBox(color: Color(0xFF2FE6FF)),
                              ),
                              Expanded(
                                child: ColoredBox(color: Color(0xFF52D6C8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('DREAMS', style: _ps(12, Colors.white, ls: 1)),
                      const SizedBox(height: 6),
                      Text(
                        '♦ DREAM OS v6 · 5 MOODS',
                        style: _mono(8, const Color(0xFFB79FDD), ls: 1),
                        softWrap: false,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: 60,
                child: Transform.translate(
                  offset: Offset(sx, 0),
                  child: Transform(
                    transform: Matrix4.skewX(-20 * pi / 180),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0xA6FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                        ),
                      ),
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
}

// ─────────────────────────────────────────────────────────────
// 작은 부품들
// ─────────────────────────────────────────────────────────────
class _Scanlines extends StatelessWidget {
  const _Scanlines();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ScanlinePainter());
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x40000000);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('LOADING', style: _ps(9, const Color(0xFFB79FDD), ls: 1)),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 14,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: _kViolet, width: 2),
            ),
            child: CustomPaint(
              painter: _BarFillPainter(progress),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 40,
          child: Text('${(progress * 100).round()}%', style: _ps(9, _kText)),
        ),
      ],
    );
  }
}

class _BarFillPainter extends CustomPainter {
  _BarFillPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * progress;
    final p = Paint()..color = _kViolet;
    for (double x = 0; x < w; x += 10) {
      canvas.drawRect(Rect.fromLTWH(x, 0, min(8.0, w - x), size.height), p);
    }
  }

  @override
  bool shouldRepaint(_BarFillPainter old) => old.progress != progress;
}

class _DPad extends StatelessWidget {
  const _DPad();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF160B2E),
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(color: Color(0xFF0A0518), offset: Offset(0, 4)),
        ],
      ),
    );
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Positioned(left: 34, top: 0, child: bar(32, 100)),
          Positioned(left: 0, top: 34, child: bar(100, 32)),
          Positioned(
            left: 42,
            top: 42,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment(-.2, -.3),
                  colors: [Color(0xFF2A1A4A), Color(0xFF0C0720)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 눌리면 builder에 pressed=true가 전달되는 버튼 래퍼.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.builder,
    required this.onTap,
    required this.label,
  });

  final Widget Function(bool pressed) builder;
  final VoidCallback? onTap;
  final String label;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.onTap,
          child: widget.builder(_down),
        ),
      ),
    );
  }
}

class _SkipButton extends StatefulWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'SKIP',
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hover ? _kViolet : const Color(0xFF4E2F86),
              ),
            ),
            child: Text(
              'SKIP ▸▸',
              style: _mono(
                11,
                _hover ? Colors.white : const Color(0xFFB79FDD),
                ls: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 말풍선/버튼 등장용 팝 (0.6배 → 1.06배 → 1배).
class _Pop extends StatefulWidget {
  const _Pop({
    super.key,
    required this.child,
    required this.duration,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.value;
        final scale = v < .7
            ? lerpDouble(.6, 1.06, Curves.easeOut.transform(v / .7))
            : lerpDouble(1.06, 1, (v - .7) / .3);
        return Opacity(
          opacity: Curves.easeOut.transform(v),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child, required this.duration});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: duration,
    curve: Curves.easeOut,
    builder: (context, v, c) => Opacity(opacity: v, child: c),
    child: child,
  );
}

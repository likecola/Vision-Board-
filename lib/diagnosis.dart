import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'diagnosis_data.dart';
import 'intro.dart' show Mascot;
import 'web_synth.dart';

// ─────────────────────────────────────────────────────────────
// DREAM OS 진단 — "꾸미기가 곧 테스트"
//
// 안내(꿈별이) → 3라운드(카드 6장 중 2장) → 분석 → 수집 카드 형태의 결과.
// 콘솔의 D-패드 / A / B 와 키보드, 터치 모두로 조작한다.
// ─────────────────────────────────────────────────────────────

enum DiagKey { up, down, left, right, a, b }

/// 콘솔 버튼(D-패드/A/B)을 진단 화면으로 전달하는 다리.
class DiagnosisController {
  void Function(DiagKey)? _handler;
  void press(DiagKey k) => _handler?.call(k);
}

class DiagPalette {
  const DiagPalette({
    required this.accent,
    required this.accent2,
    required this.text,
    required this.muted,
    required this.bg,
    required this.glow,
  });

  final Color accent, accent2, text, muted, bg, glow;
}

const _ink = Color(0xFF2A1450);
const _bubbleBg = Color(0xFFFFF6E0);

TextStyle _jua(double size, Color color, {double height = 1.25}) => TextStyle(
  fontFamily: 'Jua',
  fontSize: size,
  color: color,
  height: height,
  decoration: TextDecoration.none,
);

TextStyle _ps(double size, Color color, {double ls = 0}) => TextStyle(
  fontFamily: 'PressStart2P',
  fontSize: size,
  color: color,
  letterSpacing: ls,
  decoration: TextDecoration.none,
);

enum _Phase { guide, round, analyzing, result }

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({
    super.key,
    required this.palette,
    required this.paletteOf,
    required this.controller,
    required this.onResult,
    required this.onBuild,
    required this.onClose,
  });

  /// 지금 콘솔 무드의 팔레트
  final DiagPalette palette;

  /// 무드 키 → 팔레트 (결과 카드용)
  final DiagPalette Function(String mood) paletteOf;
  final DiagnosisController controller;

  /// 분석이 끝나 결과가 정해졌을 때 (저장·효과음용)
  final void Function(String mood, Map<String, int> scores) onResult;

  /// "내 보드 만들기"
  final void Function(String mood) onBuild;

  /// 건너뛰기
  final VoidCallback onClose;

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.guide;
  int _round = 0;
  late List<List<DiagCard>> _deck;
  final List<List<int>> _picks = [[], [], []];
  int _cursor = 0;
  bool _cursorOn = false;
  int _cols = 3;
  String _sayKo = '', _sayEn = '';
  String? _result;
  Map<String, int> _scores = {};
  Timer? _timer;
  final _rng = Random();
  late final AnimationController _clock;
  final _cardKeys = List.generate(6, (_) => GlobalKey());
  final _focus = FocusNode(debugLabel: 'diagnosis');

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..repeat();
    _newDeck();
    _say(
      '안녕, 나는 꿈별이! 카드를 보고 끌리는 걸 라운드마다 2장씩 골라줘. 정답은 없어!',
      "Hi, I'm Dreamy! Pick the 2 cards that pull you each round. No wrong answers!",
    );
    widget.controller._handler = _onKey;
    appLang.addListener(_rebuild);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller._handler = null;
    appLang.removeListener(_rebuild);
    _clock.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _newDeck() {
    _deck = [
      for (final r in diagRounds) ([...r.cards]..shuffle(_rng)),
    ];
    for (final p in _picks) {
      p.clear();
    }
    _round = 0;
    _cursor = 0;
    _cursorOn = false;
    _result = null;
  }

  void _say(String ko, String en) {
    _sayKo = ko;
    _sayEn = en;
  }

  // ── 입력 ──
  static const _nextIdx = 6; // 커서 6 = "A 다음" 버튼
  int _lastCard = 0;

  void _onKey(DiagKey k) {
    if (!mounted) return;
    _cursorOn = true;
    switch (_phase) {
      case _Phase.guide:
        if (k == DiagKey.a) _startRounds();
      case _Phase.round:
        _roundKey(k);
      case _Phase.analyzing:
        break;
      case _Phase.result:
        if (k == DiagKey.a) {
          WebSynth.instance.blip();
          widget.onBuild(_result!);
        } else if (k == DiagKey.b) {
          _retry();
        }
    }
  }

  void _roundKey(DiagKey k) {
    final picks = _picks[_round];
    switch (k) {
      case DiagKey.left:
      case DiagKey.right:
      case DiagKey.up:
      case DiagKey.down:
        WebSynth.instance.dpadBlip();
        setState(() {
          if (_cursor == _nextIdx) {
            // 버튼에서는 왼쪽/위로 카드로 돌아간다.
            if (k == DiagKey.left || k == DiagKey.up) _cursor = _lastCard;
            return;
          }
          final d = switch (k) {
            DiagKey.left => -1,
            DiagKey.right => 1,
            DiagKey.up => -_cols,
            _ => _cols,
          };
          final n = _cursor + d;
          if (k == DiagKey.down && n > 5 && picks.length == 2) {
            _lastCard = _cursor;
            _cursor = _nextIdx;
          } else {
            _cursor = n.clamp(0, 5);
          }
        });
        if (_cursor != _nextIdx) _ensureVisible(_cursor);
      case DiagKey.a:
        if (_cursor == _nextIdx) {
          _next();
        } else {
          _toggle(_cursor);
        }
      case DiagKey.b:
        if (picks.isNotEmpty) {
          final removed = picks.removeLast();
          setState(() {
            _cursor = removed;
            _say('다시 골라볼까?', 'Want to choose again?');
          });
          WebSynth.instance.pickBlip(false);
        } else if (_round > 0) {
          setState(() {
            _round--;
            _cursor = 0;
            _say('앞 라운드로 돌아왔어.', 'Back to the last round.');
          });
        } else {
          setState(() => _phase = _Phase.guide);
        }
    }
  }

  void _ensureVisible(int i) {
    final c = _cardKeys[i].currentContext;
    if (c != null) {
      Scrollable.ensureVisible(
        c,
        duration: const Duration(milliseconds: 180),
        alignment: .5,
      );
    }
  }

  void _startRounds() {
    WebSynth.instance.startDiagnosis();
    setState(() {
      _phase = _Phase.round;
      _say('카드 중에서 끌리는 2장을 골라봐!', 'Pick the 2 cards that pull you!');
    });
  }

  static const _reactions = <(String, String)>[
    ('오, 이거야?', 'Oh, this one?'),
    ('좋은 선택!', 'Nice pick!'),
    ('나도 이거 좋아해 ✦', 'I like this one too ✦'),
    ('음~ 그렇구나', 'Hmm, I see~'),
    ('느낌 와!', 'I can feel it!'),
  ];

  void _toggle(int i) {
    final picks = _picks[_round];
    setState(() {
      _cursor = i;
      if (picks.contains(i)) {
        picks.remove(i);
        if (_cursor == _nextIdx) _cursor = i;
        _say('다시 골라볼까?', 'Want to choose again?');
        WebSynth.instance.pickBlip(false);
      } else if (picks.length < 2) {
        picks.add(i);
        WebSynth.instance.pickBlip(true);
        if (picks.length == 2) {
          if (_cursorOn) {
            _lastCard = i;
            _cursor = _nextIdx;
          }
          _say(
            _round == 2 ? '이 둘이면 됐어! A를 눌러 결과를 볼까?' : '이 둘이면 됐어! A를 눌러 다음으로!',
            _round == 2 ? "That's enough! Press A for your result!" : "That's enough! Press A to continue!",
          );
        } else {
          final r = _reactions[_rng.nextInt(_reactions.length)];
          _say(r.$1, r.$2);
        }
      } else {
        _say('2장까지만 고를 수 있어! 하나를 빼볼래?', 'Only 2! Remove one first?');
      }
    });
  }

  void _next() {
    if (_picks[_round].length < 2) return;
    WebSynth.instance.startDiagnosis();
    if (_round < 2) {
      setState(() {
        _round++;
        _cursor = 0;
        _say('좋아! 다음 질문이야.', 'Great! Next question.');
      });
    } else {
      _analyze();
    }
  }

  void _analyze() {
    setState(() => _phase = _Phase.analyzing);
    _timer = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      final scores = <String, int>{};
      for (var r = 0; r < 3; r++) {
        for (final i in _picks[r]) {
          final m = _deck[r][i].mood;
          scores[m] = (scores[m] ?? 0) + 1;
        }
      }
      final top = scores.values.reduce(max);
      final winners = scores.entries.where((e) => e.value == top).map((e) => e.key).toList();
      final result = winners[_rng.nextInt(winners.length)];
      setState(() {
        _scores = scores;
        _result = result;
        _phase = _Phase.result;
      });
      widget.onResult(result, scores);
    });
  }

  void _retry() {
    setState(() {
      _newDeck();
      _phase = _Phase.guide;
      _say('다시 해보자! 이번엔 어떤 카드가 끌릴까?', "Let's go again! Which cards pull you now?");
    });
  }

  // ── 공통 부품 ──
  double _wave(double t, double period) =>
      (1 - cos(2 * pi * ((t % period) / period))) / 2;

  Widget _bubble(String text, {double size = 16, double maxW = 360}) {
    final p = widget.palette;
    return Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bubbleBg,
        border: Border.all(color: _ink, width: 3),
        boxShadow: [BoxShadow(color: p.bg.withValues(alpha: .6), offset: const Offset(4, 4))],
      ),
      child: Text(text, style: _jua(size, _ink, height: 1.35)),
    );
  }

  Widget _mascot(double px, {String? costume, bool bob = true}) {
    final t = _clock.value * 3600.0;
    final closed = t >= 2.6 && (t % 2.6) < .15;
    return Transform.translate(
      offset: Offset(0, bob ? -6 * _wave(t, 1.2) : 0),
      child: Mascot(px: px, closed: closed, costume: costume),
    );
  }

  Widget _pill(
    String label,
    VoidCallback? onTap, {
    bool filled = false,
    double size = 14,
    bool focused = false,
  }) {
    final p = widget.palette;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: filled && enabled ? p.accent : Colors.white.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: focused ? p.text : (enabled ? p.accent : p.muted.withValues(alpha: .3)),
                width: focused ? 3 : 1.5,
              ),
              boxShadow: filled && enabled
                  ? [BoxShadow(color: p.glow, blurRadius: focused ? 24 : 14)]
                  : null,
            ),
            child: Text(
              label,
              style: _jua(
                size,
                filled && enabled ? p.bg : (enabled ? p.text : p.muted.withValues(alpha: .5)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    final p = widget.palette;
    final blink = (_clock.value * 3600.0 % 1.0) < .5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: blink ? 1 : .25),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              wide ? tr('DREAM OS · 진단 모드', 'DREAM OS · DIAGNOSTIC') : 'DREAM OS',
              style: _ps(9, p.accent, ls: 1),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_phase == _Phase.round) ...[
            if (wide) ...[
              Text('ROUND ${_round + 1}/3', style: _ps(8, p.muted)),
              const SizedBox(width: 8),
            ],
            for (var r = 0; r < 3; r++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: r <= _round ? p.accent : p.muted.withValues(alpha: .3),
                ),
              ),
            const SizedBox(width: 6),
          ],
          _langToggle(),
          if (_phase != _Phase.result && _phase != _Phase.analyzing)
            Semantics(
              button: true,
              label: 'SKIP',
              child: GestureDetector(
                onTap: widget.onClose,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(tr('건너뛰기 ▸', 'SKIP ▸'), style: _jua(12, p.muted)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _langToggle() {
    final p = widget.palette;
    Widget seg(String label, String code) {
      final on = appLang.value == code;
      return GestureDetector(
        onTap: () => appLang.value = code,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: on ? p.accent : Colors.transparent,
          child: Text(label, style: _ps(7, on ? p.bg : p.muted)),
        ),
      );
    }

    return Semantics(
      label: 'language',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(border: Border.all(color: p.accent.withValues(alpha: .5))),
        child: Row(children: [seg('한', 'ko'), seg('EN', 'en')]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Positioned.fill(
      child: Focus(
        autofocus: true,
        focusNode: _focus,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          DiagKey? d;
          if (k == LogicalKeyboardKey.arrowLeft) d = DiagKey.left;
          if (k == LogicalKeyboardKey.arrowRight) d = DiagKey.right;
          if (k == LogicalKeyboardKey.arrowUp) d = DiagKey.up;
          if (k == LogicalKeyboardKey.arrowDown) d = DiagKey.down;
          if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) d = DiagKey.a;
          if (k == LogicalKeyboardKey.backspace || k == LogicalKeyboardKey.escape) d = DiagKey.b;
          if (d == null) return KeyEventResult.ignored;
          _onKey(d);
          return KeyEventResult.handled;
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.6),
              radius: 1.6,
              colors: [p.bg.withValues(alpha: .96), Colors.black.withValues(alpha: .97)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 640;
              _cols = wide ? 3 : 2;
              return AnimatedBuilder(
                animation: _clock,
                builder: (context, _) => Column(
                  children: [
                    _header(wide),
                    Expanded(
                      child: switch (_phase) {
                        _Phase.guide => _buildGuide(wide),
                        _Phase.round => _buildRound(box, wide),
                        _Phase.analyzing => _buildAnalyzing(),
                        _Phase.result => _buildResult(box, wide),
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── 안내 ──
  Widget _buildGuide(bool wide) {
    final p = widget.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mascot(wide ? 9 : 7),
            const SizedBox(height: 16),
            _bubble(tr(_sayKo, _sayEn), size: wide ? 18 : 16, maxW: 420),
            const SizedBox(height: 18),
            _pill(tr('A  시작하기', 'A  START'), () => _onKey(DiagKey.a), filled: true, size: 17),
            const SizedBox(height: 12),
            Text(
              tr('3번의 질문 · 약 30초', '3 questions · about 30 sec'),
              style: _jua(12, p.muted),
            ),
          ],
        ),
      ),
    );
  }

  // ── 라운드 ──
  Widget _buildRound(BoxConstraints box, bool wide) {
    final p = widget.palette;
    final round = diagRounds[_round];
    final picks = _picks[_round];
    final cardW = ((box.maxWidth - 36 - (_cols - 1) * 12) / _cols).clamp(110.0, 320.0);
    final last = _round == 2;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _mascot(wide ? 5 : 4),
              const SizedBox(width: 10),
              Flexible(child: _bubble(tr(_sayKo, _sayEn), size: wide ? 15 : 13, maxW: 520)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Q${_round + 1}. ${round.question}',
                  style: _jua(wide ? 22 : 18, p.text),
                ),
              ),
              Text(
                '${picks.length}/2',
                style: _ps(10, picks.length == 2 ? p.accent : p.muted),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [for (var i = 0; i < 6; i++) _card(i, cardW, wide)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  wide
                      ? tr('D-패드 이동 · A 선택 · B 취소', 'D-pad move · A pick · B undo')
                      : tr('카드를 눌러 2장 선택', 'Tap 2 cards'),
                  style: _jua(12, p.muted),
                ),
              ),
              _pill(
                last ? tr('A  결과 보기', 'A  RESULT') : tr('A  다음', 'A  NEXT'),
                picks.length == 2 ? _next : null,
                filled: true,
                focused: _cursorOn && _cursor == _nextIdx,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(int i, double w, bool wide) {
    final p = widget.palette;
    final c = _deck[_round][i];
    final picks = _picks[_round];
    final selected = picks.contains(i);
    final order = picks.indexOf(i) + 1;
    final focused = _cursorOn && _cursor == i;
    final tilt = (((i * 37 + _round * 11) % 5) - 2) * .006;
    final pm = widget.paletteOf(c.mood);
    return KeyedSubtree(
      key: _cardKeys[i],
      child: Semantics(
        button: true,
        selected: selected,
        label: c.text,
        child: GestureDetector(
          onTap: () => _toggle(i),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: w,
              constraints: BoxConstraints(minHeight: wide ? 132 : 112),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              transformAlignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(selected ? 0 : tilt)
                ..scaleByDouble(selected ? 1.04 : (focused ? 1.02 : 1.0), selected ? 1.04 : (focused ? 1.02 : 1.0), 1, 1),
              decoration: BoxDecoration(
                color: selected ? p.accent.withValues(alpha: .18) : Colors.white.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? p.accent : (focused ? p.text : p.muted.withValues(alpha: .35)),
                  width: selected || focused ? 2 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: p.glow, blurRadius: 16)]
                    : (focused ? [BoxShadow(color: p.text.withValues(alpha: .25), blurRadius: 10)] : null),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: wide ? 54 : 46,
                        height: wide ? 54 : 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pm.accent.withValues(alpha: .16),
                          border: Border.all(color: pm.accent.withValues(alpha: .55)),
                        ),
                        child: Text(c.emoji, style: TextStyle(fontSize: wide ? 28 : 24, decoration: TextDecoration.none)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c.text,
                        textAlign: TextAlign.center,
                        style: _jua(wide ? 18 : 15, selected ? p.accent : p.text, height: 1.3),
                      ),
                    ],
                  ),
                  if (selected)
                    Positioned(
                      top: -8,
                      right: -6,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                        child: Text('$order', style: _ps(8, p.bg)),
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

  // ── 분석 ──
  Widget _buildAnalyzing() {
    final p = widget.palette;
    final t = _clock.value * 3600.0;
    final dots = '.' * ((t * 3).floor() % 4);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mascot(8),
          const SizedBox(height: 18),
          Text(
            tr('꿈 패턴 분석 중', 'ANALYZING PATTERN') + dots,
            style: _jua(20, p.text),
          ),
          const SizedBox(height: 6),
          Text(tr('6개의 신호를 읽는 중…', 'reading 6 signals…'), style: _jua(13, p.muted)),
        ],
      ),
    );
  }

  // ── 결과 ──
  Widget _buildResult(BoxConstraints box, bool wide) {
    final p = widget.palette;
    final res = _result!;
    final m = diagMoods[res]!;
    final rp = widget.paletteOf(res);
    final cardW = min(box.maxWidth - 32, wide ? 420.0 : 340.0);
    final sorted = diagMoods.keys.toList()
      ..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    final second = sorted[1];
    final secondPct = ((_scores[second] ?? 0) / 6 * 100).round();
    final subtitle = appLang.value == 'en' ? m.titleKo : m.titleEn;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      child: Center(
        child: Column(
          children: [
            Container(
              width: cardW,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: rp.accent, width: 3),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rp.bg, Color.alphaBlend(rp.accent.withValues(alpha: .22), rp.bg)],
                ),
                boxShadow: [BoxShadow(color: rp.glow, blurRadius: 28)],
              ),
              child: Column(
                children: [
                  Text(tr('당신의 OS는', 'YOUR OS'), style: _ps(8, rp.muted, ls: 2)),
                  const SizedBox(height: 14),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [rp.accent.withValues(alpha: .35), Colors.transparent]),
                        ),
                      ),
                      _mascot(8, costume: m.costume),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('${m.emoji} ${m.title}', style: _jua(wide ? 32 : 28, rp.accent)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _ps(8, rp.muted, ls: 2)),
                  const SizedBox(height: 12),
                  Text(m.desc, textAlign: TextAlign.center, style: _jua(14, rp.text, height: 1.45)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final k in m.keywords)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: rp.accent.withValues(alpha: .6)),
                          ),
                          child: Text(k, style: _jua(12, rp.accent)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final key in sorted) _bar(key, key == res),
                  const SizedBox(height: 8),
                  if (secondPct > 0)
                    Text(
                      secondPct == ((_scores[res] ?? 0) / 6 * 100).round()
                          ? tr(
                              '공동 1위 ${diagMoods[second]!.titleKo} $secondPct%',
                              'Tied: ${diagMoods[second]!.titleEn} $secondPct%',
                            )
                          : tr(
                              '2위 ${diagMoods[second]!.titleKo} $secondPct%',
                              '2nd: ${diagMoods[second]!.titleEn} $secondPct%',
                            ),
                      style: _jua(12, rp.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _pill(tr('A  내 보드 만들기', 'A  BUILD MY BOARD'), () => _onKey(DiagKey.a), filled: true, size: 16),
                _pill(tr('B  다시 하기', 'B  RETRY'), _retry),
              ],
            ),
            const SizedBox(height: 4),
            Text('', style: _jua(1, p.muted)),
          ],
        ),
      ),
    );
  }

  Widget _bar(String key, bool top) {
    final m = diagMoods[key]!;
    final rp = widget.paletteOf(key);
    final pct = ((_scores[key] ?? 0) / 6 * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(m.emoji, style: const TextStyle(fontSize: 14, decoration: TextDecoration.none))),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, v, _) => Container(
                height: 10,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  widthFactor: v.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: top ? rp.accent : rp.accent.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text('$pct%', textAlign: TextAlign.right, style: _ps(8, top ? rp.accent : rp.muted)),
          ),
        ],
      ),
    );
  }
}

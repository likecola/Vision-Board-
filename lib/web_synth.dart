// ignore_for_file: non_constant_identifier_names
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

// ─────────────────────────────────────────────
// WebAudio 바인딩 (dart:js_interop)
// Dart 3.11에서는 dart:web_audio / dart:js_util 이 제거되어 직접 선언한다.
// ─────────────────────────────────────────────
@JS('AudioContext')
extension type WebAudioContext._(JSObject _) implements JSObject {
  external factory WebAudioContext();
  external num get currentTime;
  external num get sampleRate;
  external String get state;
  external JSPromise resume();
  external WebOscillatorNode createOscillator();
  external WebGainNode createGain();
  external WebAudioBuffer createBuffer(
    int channels,
    int length,
    num sampleRate,
  );
  external WebBufferSource createBufferSource();
  external JSObject get destination;
}

@JS()
extension type WebOscillatorNode._(JSObject _) implements JSObject {
  external set type(String value);
  external WebAudioParam get frequency;
  external void connect(JSObject node);
  external void start(num when);
  external void stop(num when);
}

@JS()
extension type WebGainNode._(JSObject _) implements JSObject {
  external WebAudioParam get gain;
  external void connect(JSObject node);
}

@JS()
extension type WebAudioBuffer._(JSObject _) implements JSObject {
  external void copyToChannel(JSFloat32Array source, int channel);
}

@JS()
extension type WebBufferSource._(JSObject _) implements JSObject {
  external set buffer(WebAudioBuffer value);
  external void connect(JSObject node);
  external void start(num when);
}

@JS()
extension type WebAudioParam._(JSObject _) implements JSObject {
  external set value(num v);
  external void setValueAtTime(num value, num time);
  external void exponentialRampToValueAtTime(num value, num time);
}

/// 앱 전체가 공유하는 레트로 신스.
/// 브라우저 autoplay 정책 때문에 첫 사용자 입력 이후에만 컨텍스트를 만든다.
class WebSynth {
  WebSynth._();
  static final WebSynth instance = WebSynth._();

  bool enabled = true;
  WebAudioContext? _ctx;
  final _rng = Random();

  WebAudioContext? get _audio {
    if (!enabled) return null;
    try {
      _ctx ??= WebAudioContext();
      if (_ctx!.state == 'suspended') _ctx!.resume();
      return _ctx;
    } catch (_) {
      return null;
    }
  }

  /// 단일 톤. [f2]가 있으면 [freq]에서 [f2]로 지수 스윕한다.
  void tone(
    double freq,
    double dur,
    String type,
    double peak, {
    double delay = 0,
    double? f2,
  }) {
    final ctx = _audio;
    if (ctx == null) return;
    try {
      final t0 = ctx.currentTime.toDouble() + delay;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = type;
      osc.frequency.setValueAtTime(freq, t0);
      if (f2 != null) osc.frequency.exponentialRampToValueAtTime(f2, t0 + dur);
      gain.gain.setValueAtTime(0.0001, t0);
      gain.gain.exponentialRampToValueAtTime(peak, t0 + 0.01);
      gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(t0);
      osc.stop(t0 + dur + 0.03);
    } catch (_) {}
  }

  /// 카트리지 "딸깍": 60ms 노이즈 버스트(감쇠 ^4) + 140Hz 사각파 70ms.
  void clack() {
    final ctx = _audio;
    if (ctx == null) return;
    try {
      final rate = ctx.sampleRate.toDouble();
      final n = (rate * 0.06).floor();
      final data = Float32List(n);
      for (var i = 0; i < n; i++) {
        data[i] = (_rng.nextDouble() * 2 - 1) * pow(1 - i / n, 4).toDouble();
      }
      final buf = ctx.createBuffer(1, n, rate);
      buf.copyToChannel(data.toJS, 0);
      final src = ctx.createBufferSource();
      final gain = ctx.createGain();
      gain.gain.value = 0.5;
      src.buffer = buf;
      src.connect(gain);
      gain.connect(ctx.destination);
      src.start(0);
    } catch (_) {}
    tone(140, .07, 'square', .12);
  }

  // ── 인트로 시퀀스 효과음 (INTRO_SPEC "사운드" 표) ──
  void boot() {
    tone(523, .09, 'square', .1);
    tone(784, .14, 'square', .1, delay: .08);
  }

  void power() => tone(60, .45, 'sawtooth', .05, f2: 520);
  void typeTick() => tone(1500 + _rng.nextDouble() * 400, .015, 'square', .025);
  void ok() => tone(1320, .05, 'square', .06);
  void logoDing() {
    tone(1046, .08, 'square', .1);
    tone(2093, .6, 'square', .09, delay: .09);
  }

  void startDiagnosis() {
    tone(784, .08, 'square', .1);
    tone(1175, .18, 'square', .1, delay: .08);
  }

  void blip() => tone(880, .06, 'square', .08);

  // ── 본편 앱 효과음 ──
  void buttonBlip() => tone(880, .08, 'square', .10);
  void dpadBlip() => tone(660, .05, 'square', .07);
  void pickBlip(bool on) => tone(on ? 1180 : 740, .05, 'sine', .06);

  /// 무드 전환 차임 — 무드별 시퀀스/파형.
  void moodChime(String key) {
    const seqs = {
      'manifestation': [523.0, 659.0, 784.0, 988.0],
      'soft_life': [440.0, 554.0, 659.0],
      'that_girl': [392.0, 494.0, 587.0],
      'cyber_dream': [300.0, 600.0, 466.0, 900.0],
      'wanderlust': [349.0, 415.0, 523.0],
    };
    const waves = {
      'manifestation': 'sine',
      'soft_life': 'sine',
      'that_girl': 'triangle',
      'cyber_dream': 'sawtooth',
      'wanderlust': 'sine',
    };
    final seq = seqs[key] ?? seqs['manifestation']!;
    final wave = waves[key] ?? 'sine';
    for (var i = 0; i < seq.length; i++) {
      tone(seq[i], .24, wave, .11, delay: i * 0.09);
    }
  }
}

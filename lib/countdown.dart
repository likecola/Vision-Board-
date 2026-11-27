import 'dart:async';

import 'package:flutter/material.dart';

import 'diagnosis_data.dart' show tr;

/// 2027년 1월 1일 0시(기기 현지 시간)까지 D-day + 시:분:초 카운트다운.
class NewYearCountdown extends StatefulWidget {
  const NewYearCountdown({
    super.key,
    required this.color,
    this.fontSize = 10,
    this.bold = false,
    this.letterSpacing = 1,
  });
  final Color color;
  final double fontSize;
  final bool bold;
  final double letterSpacing;

  static final DateTime target = DateTime(2027, 1, 1);

  @override
  State<NewYearCountdown> createState() => _NewYearCountdownState();
}

class _NewYearCountdownState extends State<NewYearCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final left = NewYearCountdown.target.difference(DateTime.now());
    final String text;
    if (left.isNegative) {
      text = tr('🎉 2027 시작!', '🎉 2027 IS HERE');
    } else {
      final h = left.inHours % 24, m = left.inMinutes % 60, s = left.inSeconds % 60;
      text = 'D-${left.inDays}  ${_two(h)}:${_two(m)}:${_two(s)}';
    }
    return Text(
      text,
      softWrap: false,
      style: TextStyle(
        color: widget.color,
        fontSize: widget.fontSize,
        fontFamily: 'SpaceMono',
        fontWeight: widget.bold ? FontWeight.bold : FontWeight.normal,
        letterSpacing: widget.letterSpacing,
      ),
    );
  }
}

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 앱 버전과 빌드 번호. 화면에 작게 표시해서 폰이 어느 버전을 보고 있는지 확인할 수 있다.
/// 빌드 번호는 `tools/build_web.sh` 가 `--dart-define=BUILD_ID=...` 로 넣는다.
const kAppVersion = '1.10.1';
const kBuildId = String.fromEnvironment('BUILD_ID', defaultValue: 'dev');
String get kVersionLabel => 'v$kAppVersion · $kBuildId';

/// 휴대폰/좁은 화면이면 가벼운 모드: 끊임없이 움직이는 효과와 큰 번짐 그림자를 줄여
/// GPU/메모리 부담(모바일 브라우저가 페이지를 강제로 닫는 문제)을 낮춘다.
final bool kLite =
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android ||
    (html.window.innerWidth ?? 1000) < 700;

/// 앱 버전과 빌드 번호. 화면에 작게 표시해서 폰이 어느 버전을 보고 있는지 확인할 수 있다.
/// 빌드 번호는 `tools/build_web.sh` 가 `--dart-define=BUILD_ID=...` 로 넣는다.
const kAppVersion = '1.9.8';
const kBuildId = String.fromEnvironment('BUILD_ID', defaultValue: 'dev');
String get kVersionLabel => 'v$kAppVersion · $kBuildId';

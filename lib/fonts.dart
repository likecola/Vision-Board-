import 'package:google_fonts/google_fonts.dart';

/// google_fonts 가 Jua 전체 글꼴을 등록할 때 쓰는 이름.
const kFullJuaFamily = 'Jua_regular';

/// 번들한 Jua(자주 쓰는 글자만 담은 서브셋, assets/fonts)에 없는 한글은
/// 이 전체 글꼴로 채운다. 파일이 커서(수 MB) 필요해질 때 한 번만 내려받는다.
/// 인트로에서 START 를 누를 때 미리 시작하면 진단 화면에 닿을 즈음 준비된다.
bool _started = false;
void ensureFullJua() {
  if (_started) return;
  _started = true;
  GoogleFonts.jua();
}

#!/usr/bin/env bash
# 배포용 웹 빌드. 매번 깨끗하게 빌드하고, 폰/브라우저가 옛 파일을 쓰지 못하게
# main.dart.js 의 파일 이름에 빌드 번호를 붙인다(GitHub Pages 는 파일을 10분간 캐시하게 한다).
set -euo pipefail
cd "$(dirname "$0")/.."
H="$(date +%m%d-%H%M)"

rm -rf build/web
flutter build web --release --base-href "/Vision-Board-/" --dart-define=BUILD_ID="$H"

cd build/web
mv main.dart.js "main.$H.dart.js"
perl -pi -e "s/main\\.dart\\.js/main.$H.dart.js/g" flutter_bootstrap.js
perl -pi -e "s#src=\"flutter_bootstrap\\.js\"#src=\"flutter_bootstrap.js?v=$H\"#" index.html

# 감사: 옛 이름이 남았는지, 이미지가 섞였는지
# flutter.js 안의 main.dart.js 는 로더 기본값 문자열이라 무시한다.
if grep -l "main\.dart\.js" flutter_bootstrap.js index.html >/dev/null 2>&1; then echo "WARN: main.dart.js 참조가 남아 있음"; fi
echo "images: $(find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) | wc -l)"
echo "build id: $H"

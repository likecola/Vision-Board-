import 'package:flutter/foundation.dart';

/// 앱 언어 ('ko' 기본, 'en' 선택).
final ValueNotifier<String> appLang = ValueNotifier<String>('ko');

String tr(String ko, String en) => appLang.value == 'en' ? en : ko;

class DiagMood {
  const DiagMood({
    required this.emoji,
    required this.titleKo,
    required this.titleEn,
    required this.descKo,
    required this.descEn,
    required this.kwKo,
    required this.kwEn,
    required this.costume,
  });

  final String emoji;
  final String titleKo, titleEn;
  final String descKo, descEn;
  final List<String> kwKo, kwEn;

  /// 스텔라 의상(MascotPainter costume 키)
  final String costume;

  String get title => tr(titleKo, titleEn);
  String get desc => tr(descKo, descEn);
  List<String> get keywords => appLang.value == 'en' ? kwEn : kwKo;
}

const diagMoods = <String, DiagMood>{
  'manifestation': DiagMood(
    emoji: '✨',
    titleKo: '끌어당김',
    titleEn: 'MANIFESTATION',
    descKo: '원하는 걸 먼저 크게 외치는 사람.\n말하는 대로 결국 내 것으로 만들어요.',
    descEn: 'You claim what you want out loud, first.\nWhat you speak eventually becomes yours.',
    kwKo: ['#끌어당김', '#확신', '#현실화'],
    kwEn: ['#manifest', '#conviction', '#claimit'],
    costume: 'manifestation',
  ),
  'soft_life': DiagMood(
    emoji: '🌿',
    titleKo: '소프트 라이프',
    titleEn: 'SOFT LIFE',
    descKo: '이루고 싶은 건 여유로운 일상 그 자체.\n나만의 속도로 움직이는 사람.',
    descEn: 'What you want most is an unhurried life.\nYou move strictly at your own pace.',
    kwKo: ['#여유', '#평온', '#나만의속도'],
    kwEn: ['#slow', '#calm', '#ownpace'],
    costume: 'soft_life',
  ),
  'that_girl': DiagMood(
    emoji: '💪',
    titleKo: '갓생러',
    titleEn: 'THAT GIRL',
    descKo: '큰 목표도 매일의 작은 습관으로 쪼개는 사람.\n꾸준한 루틴으로 결국 원하는 곳에 닿아요.',
    descEn: 'You slice big goals into small daily habits.\nSteady routines always get you there.',
    kwKo: ['#루틴', '#자기관리', '#꾸준함'],
    kwEn: ['#routine', '#discipline', '#daily'],
    costume: 'that_girl',
  ),
  'cyber_dream': DiagMood(
    emoji: '🔮',
    titleKo: '드림코어',
    titleEn: 'DREAMCORE',
    descKo: '남들과 다른 나만의 길을 직접 만드는 사람.\n머릿속 상상을 눈앞의 현실로 바꿔요.',
    descEn: 'You carve out a path completely your own.\nTurning wild daydreams into real life.',
    kwKo: ['#나만의길', '#감각적', '#아이디어'],
    kwEn: ['#dreamcore', '#ownpath', '#original'],
    costume: 'cyber_dream',
  ),
  'wanderlust': DiagMood(
    emoji: '🌍',
    titleKo: '노마드',
    titleEn: 'WANDERLUST',
    descKo: '이루고 싶은 건 직접 닿아 보는 경험들.\n한곳에 머물지 않는 자유로운 사람.',
    descEn: 'What you want most are places to reach.\nAlways ready for the next horizon.',
    kwKo: ['#여행', '#자유', '#새로운경험'],
    kwEn: ['#travel', '#freedom', '#explore'],
    costume: 'wanderlust',
  ),
};

class DiagCard {
  const DiagCard(this.mood, this.emoji, this.ko, this.en);
  final String mood, emoji, ko, en;
  String get text => tr(ko, en);
}

class DiagRound {
  const DiagRound(this.qKo, this.qEn, this.cards);
  final String qKo, qEn;
  final List<DiagCard> cards;
  String get question => tr(qKo, qEn);
}

/// 3라운드 × 6장 중 2장 선택.
///   1) 보드에 담고 싶은 핵심 목표  2) 지금 벗어나고 싶은 상태  3) 1년 뒤 원하는 한 줄 요약
const diagRounds = <DiagRound>[
  DiagRound(
    '지금 내 보드 한가운데 채우고 싶은 건?',
    'What do you want front and center on your board right now?',
    [
      DiagCard('manifestation', '', '모두가 인정하는 커리어 성취와 타이틀', 'Career milestones and titles everyone recognizes'),
      DiagCard('soft_life', '', '온전히 내 취향으로 채운 나만의 공간과 휴식', 'My own cozy space and uninterrupted rest'),
      DiagCard('that_girl', '', '더 건강해진 몸과 흔들림 없는 매일의 루틴', 'A stronger body and an unshakeable daily routine'),
      DiagCard('cyber_dream', '', '내 아이디어로 직접 만든 나만의 브랜드·프로젝트', 'My own brand or project built from my ideas'),
      DiagCard('wanderlust', '', '새로운 나라와 낯선 도시에서의 설레는 경험', 'Exciting experiences in new cities and countries'),
      DiagCard('manifestation', '', '돈 걱정 없이 누리는 넉넉한 경제적 여유', 'Financial abundance without worrying about money'),
    ],
  ),
  DiagRound(
    '요즘 제일 벗어나고 싶은 건?',
    'What do you want to escape most these days?',
    [
      DiagCard('manifestation', '', '내 존재감이 묻히고 뒤처지는 느낌', 'Feeling invisible or left behind'),
      DiagCard('soft_life', '', '원치 않는 약속과 빡빡한 일정', 'Unwanted plans and tight schedules'),
      DiagCard('that_girl', '', '계획대로 안 굴러가는 흐트러진 생활', 'Sloppy days with zero structure'),
      DiagCard('cyber_dream', '', '남들 다 하는 뻔하고 지루한 방식', 'Boring, copy-paste ways of doing things'),
      DiagCard('wanderlust', '', '똑같은 공간과 일상에 갇힌 답답함', 'Being stuck in the exact same place'),
      DiagCard('soft_life', '', '남 눈치 보느라 내 에너지를 쓰는 일', 'Draining my energy worrying about others'),
    ],
  ),
  DiagRound(
    '1년 뒤, 내 일상을 한 줄로 요약한다면?',
    'One year from now, how would you sum up your life?',
    [
      DiagCard('manifestation', '', '말한 대로 다 내 것이 된 한 해', 'Everything I claimed became mine'),
      DiagCard('soft_life', '', '서두르지 않고 나답게 흘러간 시간', 'Unhurried days moving at my own pace'),
      DiagCard('that_girl', '', '매일 쌓아 온 루틴이 결국 큰 성과가 된 한 해', 'Daily routines finally turning into big wins'),
      DiagCard('cyber_dream', '', '내 취향과 감각으로 꽉 채운 나만의 브랜드·작업', 'My own brand and work shaped purely by my taste'),
      DiagCard('wanderlust', '', '마음 끌리는 곳이면 어디든 훌쩍 떠났던 한 해', 'A year of taking off whenever somewhere called'),
      DiagCard('that_girl', '', '스스로 세운 목표들을 하나씩 다 이뤄낸 한 해', 'Checking off every goal I set for myself'),
    ],
  ),
];

/// 공유 보드 궁합 문구 — 정렬된 무드 페어 키 ("a+b") → (ko, en)
const diagCompat = <String, (String, String)>{
  'cyber_dream+manifestation': ('상상 현실화 듀오 — 말하는 대로 만들어내요 ⚡', 'DREAM & CREATE — turning big vision into reality ⚡'),
  'manifestation+soft_life': ('불과 물 — 팽팽한 추진력과 여유로운 균형 🔮', 'FIRE & WATER — bold drive meets quiet balance 🔮'),
  'manifestation+that_girl': ('파워 듀오 — 마음먹은 건 무조건 해내는 조합 👑', 'POWER DUO — unstoppable once you set a goal 👑'),
  'manifestation+wanderlust': ('움직이는 몽상가들 — 어디서든 판을 키워요 🚀', 'DREAMERS ON THE MOVE — making waves everywhere 🚀'),
  'cyber_dream+soft_life': ('영감과 휴식 — 치열함과 여유가 딱 맞아요 🌗', 'SPARK & CALM — creative drive meets deep rest 🌗'),
  'soft_life+that_girl': ('쉼과 달림 — 서로의 페이스를 완성해요 ☯', 'REST & GRIND — you complete each other’s pace ☯'),
  'soft_life+wanderlust': ('느린 여행자들 — 같은 속도로 세상을 봐요 🍃', 'SLOW TRAVELERS — exploring at the exact same pace 🍃'),
  'cyber_dream+that_girl': ('실행력 만렙 듀오 — 아이디어 × 꾸준함 📈', 'EXECUTION DUO — sharp ideas meet daily hustle 📈'),
  'that_girl+wanderlust': ('단단한 노마드 — 자유도 계획적으로 누려요 🧭', 'GROUNDED NOMADS — freedom, backed by discipline 🧭'),
  'cyber_dream+wanderlust': ('경계 없는 탐험가들 — 새로운 길을 찾아요 📡', 'BOUNDLESS EXPLORERS — always finding new ground 📡'),
};

String compatLine(String a, String b) {
  if (a == b) return tr('같은 주파수 — 싱크로율 100% 💯', 'SAME FREQUENCY — 100% sync 💯');
  final key = ([a, b]..sort()).join('+');
  final v = diagCompat[key];
  if (v == null) return tr('희귀한 조합 — 미지의 궁합 🌌', 'RARE PAIR — uncharted combo 🌌');
  return tr(v.$1, v.$2);
}

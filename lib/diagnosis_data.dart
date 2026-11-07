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
    descKo: '큰 꿈을 말하면 현실이 따라와요.\n입 밖으로 꺼낸 순간 이미 시작된 사람.',
    descEn: 'Big dreams, louder reality.\nYou speak things into existence.',
    kwKo: ['#끌어당김', '#주인공', '#스포트라이트'],
    kwEn: ['#manifest', '#maincharacter', '#spotlight'],
    costume: 'manifestation',
  ),
  'soft_life': DiagMood(
    emoji: '🌿',
    titleKo: '소프트 라이프',
    titleEn: 'SOFT LIFE',
    descKo: '평온이 가장 큰 사치예요.\n나만의 속도로 피어나는 사람.',
    descEn: 'Peace is your luxury.\nYou bloom at your own pace.',
    kwKo: ['#여유', '#휴식', '#햇살'],
    kwEn: ['#slow', '#rest', '#sunlight'],
    costume: 'soft_life',
  ),
  'that_girl': DiagMood(
    emoji: '💪',
    titleKo: '갓생러',
    titleEn: 'THAT GIRL',
    descKo: '꾸준함이 당신의 사랑의 언어예요.\n매일 한 칸씩 쌓아가는 사람.',
    descEn: 'Discipline is your love language.\nYou show up, every single day.',
    kwKo: ['#루틴', '#자기관리', '#새벽'],
    kwEn: ['#routine', '#discipline', '#5am'],
    costume: 'that_girl',
  ),
  'cyber_dream': DiagMood(
    emoji: '🌀',
    titleKo: '사이버 드림',
    titleEn: 'CYBER DREAM',
    descKo: '현실은 하나의 제안일 뿐이에요.\n10년 뒤를 미리 살고 있는 사람.',
    descEn: 'Reality is a suggestion.\nYou live ten years in the future.',
    kwKo: ['#네온', '#미래', '#글리치'],
    kwEn: ['#neon', '#future', '#glitch'],
    costume: 'cyber_dream',
  ),
  'wanderlust': DiagMood(
    emoji: '🌍',
    titleKo: '방랑벽',
    titleEn: 'WANDERLUST',
    descKo: '집은 계속 움직이는 목적지예요.\n수평선이 부르는 사람.',
    descEn: 'Home is a moving target.\nThe horizon keeps calling you.',
    kwKo: ['#여행', '#지도', '#수평선'],
    kwEn: ['#travel', '#maps', '#horizon'],
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

/// 3라운드 × 6장 중 2장. 라운드마다 5개 무드가 하나씩 + 보너스 1장.
const diagRounds = <DiagRound>[
  DiagRound('아침에 눈을 떴을 때, 끌리는 장면은?', 'Waking up — which scene pulls you?', [
    DiagCard('manifestation', '✨', '무대 위 조명이 나를 비추는 아침', 'Stage lights find me'),
    DiagCard('soft_life', '🌿', '느지막이 일어나 햇살과 따뜻한 차', 'Slow morning, sunlight & warm tea'),
    DiagCard('that_girl', '💪', '새벽 5시, 러닝은 이미 끝!', '5 A.M. run: already done'),
    DiagCard('cyber_dream', '🌀', '네온 불빛이 번지는 도시의 새벽', 'Neon city before dawn'),
    DiagCard('wanderlust', '🌍', '낯선 도시로 향하는 아침 기차', 'Morning train to somewhere new'),
    DiagCard('cyber_dream', '🌀', '화면 속 세계에서 눈을 뜨는 아침', 'Waking up inside the screen'),
  ]),
  DiagRound('나를 가장 잘 설명하는 한마디는?', 'Which line describes you best?', [
    DiagCard('manifestation', '✨', '원하는 건 말하는 순간 시작돼', 'Say it and it begins'),
    DiagCard('soft_life', '🌿', '쉬는 것도 일의 일부야', 'Rest is productive'),
    DiagCard('that_girl', '💪', '오늘 할 일은 오늘 끝낸다', "Today's list, done today"),
    DiagCard('cyber_dream', '🌀', '시스템을 해킹해서 새로 짠다', 'Hack the system, rewrite it'),
    DiagCard('wanderlust', '🌍', '정해진 주소 없이 흘러가도 괜찮아', 'No fixed address, just drift'),
    DiagCard('soft_life', '🌿', '좋아하는 것들로 하루를 채워', 'Fill the day with what I love'),
  ]),
  DiagRound('꿈이 이뤄진 날, 내 곁에 있는 건?', 'The day it all comes true, what is beside you?', [
    DiagCard('manifestation', '✨', '반짝이는 트로피와 샴페인', 'A trophy and champagne'),
    DiagCard('soft_life', '🌿', '린넨 이불과 갓 구운 빵', 'Linen sheets & fresh bread'),
    DiagCard('that_girl', '💪', '깔끔한 책상과 갓 내린 에스프레소', 'A clean desk & fresh espresso'),
    DiagCard('cyber_dream', '🌀', '홀로그램이 뜨는 미래의 콘솔', 'A holographic console from the future'),
    DiagCard('wanderlust', '🌍', '낡은 지도와 도장 가득한 여권', 'An old map & a stamped passport'),
    DiagCard('that_girl', '💪', '체크리스트가 전부 지워진 노트', 'A notebook with every box checked'),
  ]),
];

/// 공유 보드 궁합 문구 — 정렬된 무드 페어 키 ("a+b") → (ko, en)
const diagCompat = <String, (String, String)>{
  'cyber_dream+manifestation': ('꿈 증폭기 듀오 — 서로를 충전해줘요 ⚡', 'DREAM AMPLIFIERS — you charge each other ⚡'),
  'manifestation+soft_life': ('불과 물 — 균형이 잡혀요 🔮', 'FIRE & WATER — balance unlocked 🔮'),
  'manifestation+that_girl': ('파워 듀오 — 못 막아요 👑', 'POWER DUO — unstoppable together 👑'),
  'manifestation+wanderlust': ('움직이는 몽상가들 — 멀리 가요 🚀', 'DREAMERS ON THE MOVE — go far 🚀'),
  'cyber_dream+soft_life': ('로그인과 로그오프 — 반대라서 맞아요 🌗', 'LOGIN & LOG OFF — opposites that sync 🌗'),
  'soft_life+that_girl': ('쉼과 달림 — 서로를 완성해요 ☯', 'REST & GRIND — you complete the cycle ☯'),
  'soft_life+wanderlust': ('느린 여행자들 — 같은 속도예요 🍃', 'SLOW TRAVELERS — same gentle pace 🍃'),
  'cyber_dream+that_girl': ('미래의 CEO들 — 시스템 × 열정 📈', 'FUTURE CEOs — systems + hustle 📈'),
  'that_girl+wanderlust': ('단단한 노마드 — 자유도 노력으로 🧭', 'DISCIPLINED NOMADS — freedom, earned 🧭'),
  'cyber_dream+wanderlust': ('신호를 찾는 탐험가들 📡', 'SIGNAL SEEKERS — always exploring 📡'),
};

String compatLine(String a, String b) {
  if (a == b) return tr('같은 주파수 — 싱크로율 100% 💯', 'SAME FREQUENCY — 100% sync 💯');
  final key = ([a, b]..sort()).join('+');
  final v = diagCompat[key];
  if (v == null) return tr('희귀한 조합 — 미지의 궁합 🌌', 'RARE PAIR — uncharted combo 🌌');
  return tr(v.$1, v.$2);
}

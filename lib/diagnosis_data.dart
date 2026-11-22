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
    descKo: '막힌 곳은 해킹하고, 없는 건 직접 만드는 사람.\n10년 뒤의 시스템을 미리 살고 있어요.',
    descEn: "You hack what's locked and build what's missing.\nYou already live in the system of ten years from now.",
    kwKo: ['#해킹', '#시스템', '#미래'],
    kwEn: ['#hack', '#system', '#future'],
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
/// 카드는 모두 "꿈"에 관한 자연스러운 장면이고, 어떤 무드인지는 드러나지 않게 쓴다
/// (이모지·키워드로 결과가 짐작되지 않도록 카드에는 아이콘을 두지 않는다).
const diagRounds = <DiagRound>[
  DiagRound('꿈에서 깨어나기 직전, 가장 선명하게 남은 장면은?', 'Right before waking from a dream, which scene stayed clearest?', [
    DiagCard('manifestation', '', '수많은 박수 속에서 내 이름이 불리던 순간', 'My name being called out amid huge applause'),
    DiagCard('soft_life', '', '일출을 바라보며 따뜻한 커피를 마시던 아침', 'Sipping warm coffee while watching the sunrise'),
    DiagCard('that_girl', '', '새벽 공기를 가르며 달리다 결승선을 넘던 순간', 'Crossing the finish line after running through the dawn air'),
    DiagCard('cyber_dream', '', '빛나는 밤하늘 도시 위를 날아다니던 장면', 'Flying over a glowing city under the night sky'),
    DiagCard('wanderlust', '', '지도 없이 낯선 도시의 골목을 걷던 장면', 'Wandering the alleys of a strange city without a map'),
    DiagCard('cyber_dream', '', '우주선 창밖으로 지구가 작아지던 장면', 'Watching Earth shrink in the window of a spaceship'),
  ]),
  DiagRound('그 꿈을 향해 가는 나는, 어떤 모습일까?', 'On the way to that dream, what am I like?', [
    DiagCard('manifestation', '', '이미 이룬 사람처럼 당당하게 말하고 다녀', 'I talk with confidence, as if it were already mine'),
    DiagCard('soft_life', '', '서두르지 않고 하루하루 나답게 쌓아가', 'No rush — I build it day by day, my own way'),
    DiagCard('that_girl', '', '정해둔 만큼은 매일, 하루도 빼먹지 않고 해내', 'I do my set amount every day without skipping one'),
    DiagCard('cyber_dream', '', '아무도 안 해본 방식으로 새롭게 만들어봐', 'I try it a way nobody has, and make something new'),
    DiagCard('wanderlust', '', '한곳에 머물지 않고 여기저기서 영감을 모아', "I never stay in one place; I gather inspiration everywhere"),
    DiagCard('soft_life', '', '좋아하는 것들에 둘러싸여 천천히 가고 싶어', 'I want to go slowly, surrounded by the things I love'),
  ]),
  DiagRound('꿈이 이뤄진 날, 나는 어디서 눈을 뜰까?', 'On the day your dream comes true, where do you wake up?', [
    DiagCard('manifestation', '', '통유리창 너머로 도시가 내려다보이는 높은 집', 'A high apartment overlooking the city through floor-to-ceiling glass'),
    DiagCard('soft_life', '', '햇살 가득한 창가, 갓 구운 빵 냄새가 나는 집', 'A sunlit window and the smell of freshly baked bread'),
    DiagCard('that_girl', '', '깔끔하게 정돈된 방, 이미 하루 계획이 끝난 아침', 'A tidy room, and a morning where the day is already planned'),
    DiagCard('cyber_dream', '', '벽 전체가 화면이 되어 세상과 이어지는 집', 'A home whose whole wall is a screen linked to the world'),
    DiagCard('wanderlust', '', '바다가 보이는 낯선 나라의 작은 방', 'A small room in a foreign country with a view of the sea'),
    DiagCard('that_girl', '', '해야 할 일을 모두 끝내고 맞이한 느긋한 아침', 'A relaxed morning after finishing everything on the list'),
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

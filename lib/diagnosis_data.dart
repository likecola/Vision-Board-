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
    descKo: '원하는 걸 먼저 크게 말하는 사람.\n선언한 순간, 이미 이루기 시작했어요.',
    descEn: 'You say what you want out loud, first.\nThe moment you declare it, it has begun.',
    kwKo: ['#끌어당김', '#주인공', '#스포트라이트'],
    kwEn: ['#manifest', '#maincharacter', '#spotlight'],
    costume: 'manifestation',
  ),
  'soft_life': DiagMood(
    emoji: '🌿',
    titleKo: '소프트 라이프',
    titleEn: 'SOFT LIFE',
    descKo: '이루고 싶은 건 "여유로운 삶" 그 자체예요.\n나만의 속도로 피어나는 사람.',
    descEn: 'What you want most is an unhurried life itself.\nYou bloom at your own pace.',
    kwKo: ['#여유', '#휴식', '#햇살'],
    kwEn: ['#slow', '#rest', '#sunlight'],
    costume: 'soft_life',
  ),
  'that_girl': DiagMood(
    emoji: '💪',
    titleKo: '갓생러',
    titleEn: 'THAT GIRL',
    descKo: '목표를 매일의 한 칸으로 쪼개는 사람.\n꾸준함으로 결국 이뤄내요.',
    descEn: 'You slice every goal into daily steps.\nYou get there by showing up, every day.',
    kwKo: ['#루틴', '#자기관리', '#새벽'],
    kwEn: ['#routine', '#discipline', '#5am'],
    costume: 'that_girl',
  ),
  'cyber_dream': DiagMood(
    emoji: '🌀',
    titleKo: '사이버 드림',
    titleEn: 'CYBER DREAM',
    descKo: '없는 건 직접 만들어서 이루는 사람.\n10년 뒤의 세상을 먼저 짓고 있어요.',
    descEn: "You build what's missing to get what you want.\nYou're already constructing the world of ten years from now.",
    kwKo: ['#해킹', '#시스템', '#미래'],
    kwEn: ['#hack', '#system', '#future'],
    costume: 'cyber_dream',
  ),
  'wanderlust': DiagMood(
    emoji: '🌍',
    titleKo: '노마드',
    titleEn: 'WANDERLUST',
    descKo: '이루고 싶은 건 닿아 보는 경험들이에요.\n수평선이 부르는 사람.',
    descEn: 'What you want most are places to reach and experiences to have.\nThe horizon keeps calling you.',
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

/// 3라운드 × 6장 중 2장. 비전보드를 만들 때 실제로 하게 되는 고민의 순서를 따른다:
///   1) 무엇을 이루고 싶은가  2) 어떻게 이뤄갈 것인가  3) 이루고 나면 무엇을 느끼고 싶은가
/// 라운드마다 5개 무드가 하나씩 + 보너스 1장. 어떤 무드인지는 카드에서 드러나지 않게 쓰고,
/// 이모지·키워드로 결과가 짐작되지 않도록 카드에는 아이콘을 두지 않는다.
const diagRounds = <DiagRound>[
  DiagRound('1년 뒤, 내 보드에서 가장 이뤄져 있었으면 하는 건?', 'One year from now, what do you most want to see achieved on your board?', [
    DiagCard('manifestation', '', '내 이름이 걸린 무언가로 많은 사람 앞에 서는 것', 'Standing before a crowd with something that carries my name'),
    DiagCard('soft_life', '', '쫓기지 않고 내 하루를 내가 정하며 사는 것', 'Living unhurried, with my days decided by me'),
    DiagCard('that_girl', '', '건강한 몸과 흔들리지 않는 루틴을 갖는 것', 'Having a healthy body and a routine that never wobbles'),
    DiagCard('cyber_dream', '', '내가 만든 서비스가 실제 세상에서 돌아가는 것', 'Seeing something I built running out in the real world'),
    DiagCard('wanderlust', '', '낯선 나라에서 몇 달쯤 살아보는 것', 'Living for a few months in a country I have never been to'),
    DiagCard('cyber_dream', '', '내 아이디어 하나로 새로운 분야를 여는 것', 'Opening up a brand-new field with one idea of mine'),
  ]),
  DiagRound('그걸 이루기 위해, 이번 주에 실제로 할 수 있는 일은?', 'To make it happen, what can you actually do this week?', [
    DiagCard('manifestation', '', '목표를 주변에 선언해서 더는 물러서지 못하게 만든다', 'Announce the goal to everyone so there is no backing out'),
    DiagCard('soft_life', '', '무리 없는 작은 일 하나부터, 오늘 바로 시작한다', 'Start today with one small thing that costs me no stress'),
    DiagCard('that_girl', '', '계획표를 짜고 체크리스트를 하나씩 지워 나간다', 'Make a plan and cross off a checklist item by item'),
    DiagCard('cyber_dream', '', '필요한 도구부터 직접 만들어서 자동화해 둔다', 'Build the tools I need first and automate the rest'),
    DiagCard('wanderlust', '', '이미 해본 사람들을 찾아가 이야기를 듣고 영감을 모은다', 'Seek out people who have done it and collect their stories'),
    DiagCard('soft_life', '', '내가 정말 원하는 게 맞는지부터 차분히 정리해 본다', 'Slowly sort out whether this is truly what I want'),
  ]),
  DiagRound('그게 이뤄진 날, 가장 크게 느끼고 싶은 건?', 'On the day it comes true, what do you want to feel most?', [
    DiagCard('manifestation', '', '"봐, 말한 대로 됐지?" 하는 짜릿한 확신', 'A thrilling certainty: "See? Just like I said."'),
    DiagCard('soft_life', '', '이제 서두르지 않아도 된다는 편안한 안도감', 'A quiet relief that I no longer have to rush'),
    DiagCard('that_girl', '', '쌓아 온 노력이 결과가 됐다는 뿌듯함', 'The pride of seeing long effort turn into a result'),
    DiagCard('cyber_dream', '', '아무도 가보지 않은 곳까지 와버렸다는 설렘', 'The thrill of having gone somewhere nobody has been'),
    DiagCard('wanderlust', '', '어디서든 살아갈 수 있다는 가벼운 자유', 'The light freedom of knowing I can live anywhere'),
    DiagCard('that_girl', '', '나와 한 약속을 끝까지 지켜냈다는 자부심', 'The self-respect of keeping a promise I made to myself'),
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

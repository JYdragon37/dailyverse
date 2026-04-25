'use strict';

/**
 * DailyVerse VERSES 탭 — wind_down Zone 구절 추가
 * v_360 ~ v_379 (20개)
 * 2026-04-24
 */

const { google } = require('googleapis');
const path = require('path');

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, 'serviceAccountKey.json');

// ============================================================
// 콘텐츠 데이터
// VERSES 탭 컬럼 순서:
// A: verse_id, B: verse_short_ko, C: verse_full_ko, D: reference,
// E: book, F: chapter, G: verse, H: mode, I: theme, J: mood,
// K: season, L: weather, M: interpretation, N: application,
// O: curated, P: status, Q: notes,
// R: usage_count, S: cooldown_days, T: last_shown, U: show_count,
// V: alarm_top_ko (35자 초과 시 별도 작성, 이하 생략),
// W~Z: contemplation_* (수식 자동), AA~AG: len_* (수식 자동)
// ============================================================

const verses = [
  // -----------------------------------------------------------
  // v_360  시편 91:1
  // -----------------------------------------------------------
  {
    verse_id: 'v_360',
    verse_short_ko: '지존자의 은밀한 곳에 거하는 자는 전능자의 그늘 아래 살리로다.',
    verse_full_ko: '지존자의 은밀한 곳에 거하는 자는 전능자의 그늘 아래 살리로다.',
    reference: '시편 91:1',
    book: '시편',
    chapter: 91,
    verse: 1,
    mode: 'wind_down',
    theme: 'rest,peace,comfort',
    mood: 'cozy,calm',
    season: 'all',
    weather: 'any',
    interpretation:
      '광야를 떠돌던 이스라엘 백성이 하나님의 임재를 경험하며 지은 믿음의 고백이야.\n"은밀한 곳"은 위험이 없는 숨겨진 피난처, "그늘"은 뜨거운 광야에서 생명을 살리는 서늘한 보호를 뜻해.\n지금 이 밤, 하루를 마치고 자리에 드는 너도 그 은밀한 쉼의 자리로 들어가는 거야.',
    application:
      '오늘 밤 잠들기 전, 하루의 무게를 내려놓고 그분의 그늘 아래 조용히 들어가봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '지존자의 그늘 아래 살리로다.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_361  시편 3:5
  // -----------------------------------------------------------
  {
    verse_id: 'v_361',
    verse_short_ko: '내가 누워 자고 깨었으니 여호와께서 나를 붙드심이로다.',
    verse_full_ko: '내가 누워 자고 깨었으니 여호와께서 나를 붙드심이로다.',
    reference: '시편 3:5',
    book: '시편',
    chapter: 3,
    verse: 5,
    mode: 'wind_down',
    theme: 'peace,rest,faith',
    mood: 'cozy,calm',
    season: 'all',
    weather: 'any',
    interpretation:
      '다윗이 아들 압살롬에게 쫓겨 도망치던 극한 상황에서 쓴 시야.\n수만 명이 에워싸도 평안히 잠들었다는 건, 상황이 아닌 하나님께 안정을 두었다는 고백이거든.\n지금 네가 자리에 누울 때도, 그 붙드심은 여전히 이어지고 있어.',
    application:
      '잠들기 전 딱 한 가지만 내려놔봐. "오늘도 나를 붙드셨어"라고 조용히 고백하며 눈 감아봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '여호와께서 나를 붙드심이로다.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_362  빌립보서 4:7
  // -----------------------------------------------------------
  {
    verse_id: 'v_362',
    verse_short_ko: '하나님의 평강이 그리스도 예수 안에서 너희 마음과 생각을 지키시리라.',
    verse_full_ko:
      '모든 지각에 뛰어난 하나님의 평강이 그리스도 예수 안에서 너희 마음과 생각을 지키시리라.',
    reference: '빌립보서 4:7',
    book: '빌립보서',
    chapter: 4,
    verse: 7,
    mode: 'wind_down',
    theme: 'peace,comfort,rest',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '바울이 감옥 안에서 쓴 편지야. "모든 지각에 뛰어난"은 인간의 이해를 넘어서는 평강이라는 뜻이야.\n마음의 문을 지키는 파수꾼처럼, 하나님의 평강이 오늘 밤 네 걱정과 불안이 들어오지 못하게 막아줘.\n이성으로 해결 못한 불안도, 그분의 평강이 대신 지켜줄 수 있어.',
    application:
      '오늘 밤 잠들기 전, 내일 걱정을 종이에 적고 덮어봐. "이건 하나님이 지키실 거야"라는 고백과 함께.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '하나님의 평강이 너희 마음을 지키시리라.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_363  시편 62:1
  // -----------------------------------------------------------
  {
    verse_id: 'v_363',
    verse_short_ko: '나의 영혼이 잠잠히 하나님만 바람이여, 나의 구원이 그에게서 나는도다.',
    verse_full_ko:
      '나의 영혼이 잠잠히 하나님만 바람이여, 나의 구원이 그에게서 나는도다.',
    reference: '시편 62:1',
    book: '시편',
    chapter: 62,
    verse: 1,
    mode: 'wind_down',
    theme: 'stillness,peace,rest',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '다윗이 대적들의 위협 속에서 하나님 앞에 고요히 앉아 쓴 고백이야.\n"잠잠히"는 소란이 없다는 뜻이 아니라, 소란 속에서도 흔들리지 않는 내면의 고요함이야.\n하루가 끝나는 이 시간, 마음을 비우고 그분 앞에 조용히 앉아있는 것 자체가 신앙이야.',
    application:
      '지금 방 불 끄고 30초만 아무것도 하지 말고 조용히 있어봐. 그 고요함 속에서 그분을 바라봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '나의 영혼이 잠잠히 하나님만 바람이여.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_364  마가복음 6:31
  // -----------------------------------------------------------
  {
    verse_id: 'v_364',
    verse_short_ko: '너희는 따로 한적한 곳에 와서 잠깐 쉬어라.',
    verse_full_ko:
      '이는 오고 가는 사람이 많아 음식 먹을 겨를도 없음이라.\n이에 이르시되, 너희는 따로 한적한 곳에 와서 잠깐 쉬어라 하시니.',
    reference: '마가복음 6:31',
    book: '마가복음',
    chapter: 6,
    verse: 31,
    mode: 'wind_down',
    theme: 'rest,comfort,peace',
    mood: 'cozy,calm',
    season: 'all',
    weather: 'any',
    interpretation:
      '제자들이 쉴 틈도 없이 사역하고 돌아왔을 때 예수님이 직접 하신 말씀이야.\n"한적한 곳"은 도망이 아니라, 다시 채워지기 위해 필요한 의도적인 물러남이거든.\n쉬는 것도 믿음이야. 오늘 밤 이 자리가 바로 그 한적한 곳이야.',
    application:
      '오늘 밤은 정말 잘 쉬어도 돼. 예수님이 직접 쉬라고 하셨잖아. 편하게 자.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '너희는 따로 한적한 곳에 와서 잠깐 쉬어라.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_365  시편 134:1
  // -----------------------------------------------------------
  {
    verse_id: 'v_365',
    verse_short_ko: '여호와의 집에 밤에 서 있는 여호와의 모든 종들아 여호와를 송축하라.',
    verse_full_ko:
      '여호와의 종들아, 여호와를 송축하라.\n밤에 여호와의 집에 서 있는 자들아.',
    reference: '시편 134:1',
    book: '시편',
    chapter: 134,
    verse: 1,
    mode: 'wind_down',
    theme: 'gratitude,peace,stillness',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '성전에서 밤을 지키던 제사장들에게 보내는 마지막 시편이야.\n밤을 두려움의 시간이 아닌 하나님을 예배하는 시간으로 여긴 사람들의 노래거든.\n하루가 끝나는 이 밤, 잠들기 전 짧게 감사를 드리는 것이 오늘의 예배가 될 수 있어.',
    application:
      '자리에 눕기 전 오늘 하루 중 한 가지만 감사해봐. 크지 않아도 돼, 진심이면 충분해.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '밤에 여호와를 송축하라.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_366  에베소서 4:26
  // -----------------------------------------------------------
  {
    verse_id: 'v_366',
    verse_short_ko: '해가 지도록 분을 품지 말고.',
    verse_full_ko:
      '분을 내어도 죄를 짓지 말며, 해가 지도록 분을 품지 말고.',
    reference: '에베소서 4:26',
    book: '에베소서',
    chapter: 4,
    verse: 26,
    mode: 'wind_down',
    theme: 'peace,reflection,comfort',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '바울이 에베소 교인들에게 공동체 안에서 관계를 어떻게 맺어야 하는지 가르친 말씀이야.\n감정 자체가 죄가 아니야. 하지만 그걸 하루 끝까지 쥐고 있는 게 문제야.\n오늘 누군가에게 서운했다면, 그걸 그냥 안고 자지 말고 이 밤에 내려놓아봐.',
    application:
      '오늘 마음에 걸리는 사람 이름 떠올려봐. 그리고 "하나님, 이건 당신께 드릴게요" 하고 내려놔봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '해가 지도록 분을 품지 말고.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_367  잠언 3:24
  // -----------------------------------------------------------
  {
    verse_id: 'v_367',
    verse_short_ko: '네가 누울 때에 두려워하지 아니하겠고 네가 누우면 네 잠이 달리로다.',
    verse_full_ko:
      '네가 누울 때에 두려워하지 아니하겠고, 네가 누우면 네 잠이 달리로다.',
    reference: '잠언 3:24',
    book: '잠언',
    chapter: 3,
    verse: 24,
    mode: 'wind_down',
    theme: 'peace,rest,comfort',
    mood: 'cozy,calm',
    season: 'all',
    weather: 'any',
    interpretation:
      '잠언은 하나님의 지혜를 따르는 삶에는 밤의 두려움도 사라진다고 말해.\n달다는 것은 맛있다는 뜻이기도 하지만, 아무것도 나를 해치지 못하는 안전한 잠을 가리켜.\n지혜의 근원이신 분이 너의 밤을 지켜주신다는 약속이야.',
    application:
      '오늘 밤은 억지로 잠 청하지 않아도 돼. 그분이 지키신다는 걸 믿고 그냥 눕기만 해봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '네가 누으면 네 잠이 달리로다.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_368  요한1서 3:20
  // -----------------------------------------------------------
  {
    verse_id: 'v_368',
    verse_short_ko: '하나님은 우리 마음보다 크시고 모든 것을 아시느니라.',
    verse_full_ko:
      '우리 마음이 혹 우리를 책망할지라도 하나님은 우리 마음보다 크시고 모든 것을 아시느니라.',
    reference: '요한1서 3:20',
    book: '요한1서',
    chapter: 3,
    verse: 20,
    mode: 'wind_down',
    theme: 'comfort,peace,grace',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '요한이 자기 자신을 책망하며 마음이 흔들리는 사람들에게 쓴 편지야.\n오늘 하루 부족한 내 모습을 마음이 비난하더라도, 하나님은 그보다 훨씬 크셔.\n내가 나를 정죄하는 것보다 그분의 앎과 사랑이 더 깊다는 게 오늘 밤의 위로야.',
    application:
      '오늘 잘 못했던 것 하나가 생각난다면, "하나님이 나보다 더 잘 아셔"라고 말해봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '하나님은 우리 마음보다 크시고 모든 것을 아시느니라.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_369  시편 121:7-8
  // -----------------------------------------------------------
  {
    verse_id: 'v_369',
    verse_short_ko: '여호와께서 너를 지켜 모든 환난을 면케 하시며 또 네 영혼을 지키시리로다.',
    verse_full_ko:
      '여호와께서 너를 지켜 모든 환난을 면케 하시며, 또 네 영혼을 지키시리로다.\n여호와께서 너의 출입을 지금부터 영원까지 지키시리로다.',
    reference: '시편 121:7-8',
    book: '시편',
    chapter: 121,
    verse: 7,
    mode: 'wind_down',
    theme: 'peace,rest,faith',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '예루살렘으로 성전 순례를 떠나던 이스라엘 사람들이 길에서 부르던 시야.\n"출입을 지키신다"는 것은 나가는 것과 돌아오는 것, 삶의 모든 과정을 하나님이 책임지신다는 뜻이야.\n오늘 하루 나갔다 돌아온 너의 모든 시간도 그 손 안에 있었어.',
    application:
      '오늘 하루 무사히 돌아왔잖아. 그 자체로 이미 지키심을 받은 거야. 감사하며 눈 감아봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '여호와께서 너의 출입을 영원까지 지키시리로다.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_370  골로새서 3:15
  // -----------------------------------------------------------
  {
    verse_id: 'v_370',
    verse_short_ko: '그리스도의 평강이 너희 마음을 주장하게 하라.',
    verse_full_ko:
      '그리스도의 평강이 너희 마음을 주장하게 하라.\n너희는 평강을 위하여 한 몸으로 부르심을 받았나니, 또한 너희는 감사하는 자가 되라.',
    reference: '골로새서 3:15',
    book: '골로새서',
    chapter: 3,
    verse: 15,
    mode: 'wind_down',
    theme: 'peace,gratitude,rest',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '바울이 골로새 교인들에게 그리스도 안에서의 새 삶을 권면하며 쓴 말씀이야.\n"주장하게 하라"는 것은 걱정이나 불안이 아닌 평강이 내 마음의 중심을 차지하게 허락하라는 뜻이야.\n오늘 밤 네 마음의 자리에 무엇이 앉아 있는지 점검해봐.',
    application:
      '지금 마음속에 걱정이 앉아 있다면, 자리를 평강에게 내어줘봐. "이 자리는 평강 거야"라고 말해봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '그리스도의 평강이 너희 마음을 주장하게 하라.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_371  이사야 32:18
  // -----------------------------------------------------------
  {
    verse_id: 'v_371',
    verse_short_ko: '내 백성이 화평한 집과 안전한 거처와 조용한 쉬는 곳에 있으려니와.',
    verse_full_ko:
      '내 백성이 화평한 집과 안전한 거처와 조용한 쉬는 곳에 있으려니와.',
    reference: '이사야 32:18',
    book: '이사야',
    chapter: 32,
    verse: 18,
    mode: 'wind_down',
    theme: 'peace,rest,comfort',
    mood: 'cozy,calm',
    season: 'all',
    weather: 'any',
    interpretation:
      '이사야가 하나님의 통치가 완성될 때 하나님의 백성이 누릴 평화를 그린 말씀이야.\n화평, 안전, 조용함은 하나님 나라의 특성이야. 그리고 그건 먼 미래의 이야기만이 아니야.\n오늘 밤 네가 누운 이 자리가 하나님이 예비하신 조용한 쉬는 곳이 될 수 있어.',
    application:
      '오늘 밤 자리를 정돈하고 누우며 이렇게 말해봐. "이 자리가 하나님이 주신 안전한 쉼이야."',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '조용한 쉬는 곳에 있으려니와.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_372  시편 131:1-2
  // -----------------------------------------------------------
  {
    verse_id: 'v_372',
    verse_short_ko: '내 영혼이 젖 뗀 아이와 같도다, 젖 뗀 아이와 같이 내 영혼이 내 속에 있도다.',
    verse_full_ko:
      '여호와여, 내 마음이 교만치 아니하고 내 눈이 높지 아니하오며,\n내가 큰 일과 미치지 못할 기이한 일을 힘쓰지 아니하나이다.\n실로 내가 내 영혼으로 고요하고 평온케 하기를 젖 뗀 아이가 그 어미 품에 있음 같게 하였나니,\n내 영혼이 젖 뗀 아이와 같도다.',
    reference: '시편 131:1-2',
    book: '시편',
    chapter: 131,
    verse: 1,
    mode: 'wind_down',
    theme: 'stillness,peace,rest',
    mood: 'cozy,calm',
    season: 'all',
    weather: 'any',
    interpretation:
      '다윗이 하나님 앞에서 겸손히 자신의 마음을 내려놓은 짧은 시야.\n젖 뗀 아이가 어미 품에서 더 이상 배고파서가 아니라 그냥 안겨 있는 것처럼, 아무것도 구하지 않고 그냥 함께 있는 안식이야.\n오늘 밤 네 영혼도 그 품에서 그냥 쉬어도 돼.',
    application:
      '오늘 밤은 기도 잘하려는 부담 내려놔봐. 그냥 하나님 품에 안겨 쉬어도 충분해.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '내 영혼이 젖 뗀 아이와 같도다.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_373  누가복음 12:32
  // -----------------------------------------------------------
  {
    verse_id: 'v_373',
    verse_short_ko: '적은 무리여 무서워 말라, 너희 아버지께서 그 나라를 너희에게 주시기를 기뻐하시느니라.',
    verse_full_ko:
      '적은 무리여 무서워 말라, 너희 아버지께서 그 나라를 너희에게 주시기를 기뻐하시느니라.',
    reference: '누가복음 12:32',
    book: '누가복음',
    chapter: 12,
    verse: 32,
    mode: 'wind_down',
    theme: 'comfort,peace,rest',
    mood: 'cozy,calm',
    season: 'all',
    weather: 'any',
    interpretation:
      '예수님이 제자들의 작음과 두려움을 알면서도 하신 말씀이야.\n"적은 무리"는 보잘것없어 보이는 존재지만, 아버지의 기쁨이 그 안에 있어.\n오늘 하루 내가 너무 작고 부족하게 느껴졌더라도, 아버지의 기쁨이 나를 향해 있다는 걸 기억해봐.',
    application:
      '오늘 하루 작게 느껴졌다면 괜찮아. 아버지가 너를 기쁘게 여기신다는 걸 기억하며 눈 감아봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '적은 무리여 무서워 말라.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_374  이사야 54:10
  // -----------------------------------------------------------
  {
    verse_id: 'v_374',
    verse_short_ko: '나의 인자가 네게서 떠나지 아니하며 나의 화평의 언약이 흔들리지 아니하리라.',
    verse_full_ko:
      '산들이 떠나며 언덕들이 옮길지라도, 나의 인자가 네게서 떠나지 아니하며,\n나의 화평의 언약이 흔들리지 아니하리라. 나는 너를 긍휼히 여기는 여호와라.',
    reference: '이사야 54:10',
    book: '이사야',
    chapter: 54,
    verse: 10,
    mode: 'wind_down',
    theme: 'comfort,peace,faith',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '포로 생활로 지쳐 있던 이스라엘에게 하나님이 회복을 약속하신 말씀이야.\n"산이 떠나더라도"는 세상에서 가장 안정적인 것이 사라져도 괜찮다는 뜻이야. 하나님의 사랑이 그보다 더 견고하기 때문이야.\n오늘 하루가 흔들렸어도, 그 언약은 흔들리지 않았어.',
    application:
      '오늘 하루 흔들렸던 순간을 떠올려봐. 그때도 하나님의 사랑은 그 자리에 있었어. 그걸 기억하며 자.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '나의 인자가 네게서 떠나지 아니하리라.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_375  시편 16:7
  // -----------------------------------------------------------
  {
    verse_id: 'v_375',
    verse_short_ko: '나를 훈계하신 여호와를 송축할지라, 밤마다 내 심장이 나를 교훈하도다.',
    verse_full_ko:
      '나를 훈계하신 여호와를 송축할지라, 밤마다 내 심장이 나를 교훈하도다.',
    reference: '시편 16:7',
    book: '시편',
    chapter: 16,
    verse: 7,
    mode: 'wind_down',
    theme: 'reflection,gratitude,stillness',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '다윗이 하나님과의 깊은 신뢰 관계를 노래한 시야.\n"밤마다 심장이 교훈한다"는 것은 낮의 소란이 잦아든 밤에, 마음 깊은 곳에서 하나님의 음성이 들린다는 뜻이야.\n오늘 밤 조용해지면, 그분이 낮 동안 말씀하셨던 것들이 들릴 수도 있어.',
    application:
      '지금 조용히 오늘 하루를 돌아봐봐. 그분이 무언가를 가르쳐주셨을 수도 있어. 그게 뭔지 떠올려봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '밤마다 내 심장이 나를 교훈하도다.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_376  데살로니가전서 5:23
  // -----------------------------------------------------------
  {
    verse_id: 'v_376',
    verse_short_ko: '평강의 하나님이 친히 너희로 온전히 거룩하게 하시고.',
    verse_full_ko:
      '평강의 하나님이 친히 너희로 온전히 거룩하게 하시고,\n또 너희 온 영과 혼과 몸이 우리 주 예수 그리스도 강림하실 때에 흠 없게 보전되기를 원하노라.',
    reference: '데살로니가전서 5:23',
    book: '데살로니가전서',
    chapter: 5,
    verse: 23,
    mode: 'wind_down',
    theme: 'peace,rest,faith',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '바울이 데살로니가 교인들에게 보낸 편지 끝에 축복으로 선언한 말씀이야.\n내가 노력해서 완전해지는 게 아니라, 평강의 하나님이 친히 온전하게 하신다는 약속이야.\n오늘 하루 부족했어도, 그분이 보전하시고 완성해 나가신다는 게 오늘 밤의 위안이야.',
    application:
      '오늘 부족한 부분이 보인다면, 스스로 고치려 애쓰기 전에 그분께 맡겨봐. 친히 하신다고 하셨잖아.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '평강의 하나님이 친히 너희를 온전히 하시고.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_377  룻기 2:12
  // -----------------------------------------------------------
  {
    verse_id: 'v_377',
    verse_short_ko: '이스라엘의 하나님 여호와께서 그 날개 아래 보호를 받으러 온 네게 온전한 상 주시기를 원하노라.',
    verse_full_ko:
      '이스라엘의 하나님 여호와께서 그 날개 아래 보호를 받으러 온 네게 온전한 상 주시기를 원하노라.',
    reference: '룻기 2:12',
    book: '룻기',
    chapter: 2,
    verse: 12,
    mode: 'wind_down',
    theme: 'comfort,peace,rest',
    mood: 'cozy,calm',
    season: 'all',
    weather: 'any',
    interpretation:
      '보아스가 고향을 버리고 시어머니를 따라온 룻에게 건넨 말이야.\n"날개 아래 보호"는 새가 새끼를 품듯 하나님이 연약한 자를 품어주신다는 부드러운 표현이야.\n오늘 하루 어렵게 버텨온 너도 그 날개 아래 품어지고 있어.',
    application:
      '오늘 버티느라 수고했어. 그 모든 시간 동안 그분의 날개 아래 있었다는 걸 기억하며 눈 감아봐.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '그 날개 아래 보호를 받으러 온 네게 온전한 상 주시기를 원하노라.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_378  히브리서 4:9-10
  // -----------------------------------------------------------
  {
    verse_id: 'v_378',
    verse_short_ko: '그런즉 안식할 때가 하나님의 백성에게 남아 있도다.',
    verse_full_ko:
      '그런즉 안식할 때가 하나님의 백성에게 남아 있도다.\n이미 그의 안식에 들어간 자는 하나님이 자기 일을 쉬심과 같이 자기 일을 쉬느니라.',
    reference: '히브리서 4:9-10',
    book: '히브리서',
    chapter: 4,
    verse: 9,
    mode: 'wind_down',
    theme: 'rest,peace,stillness',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '히브리서는 지쳐있는 신앙 공동체에게 하나님의 안식이 실재한다고 선언해.\n창조 후 하나님이 쉬신 것처럼, 그 쉼이 하나님의 백성에게도 약속되어 있어.\n오늘 밤 잠드는 것도 하나님이 설계하신 안식 안에 들어가는 행위야.',
    application:
      '오늘 밤 자리에 누우며 이렇게 말해봐. "나도 하나님의 안식 안으로 들어가." 그리고 편히 자.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '안식할 때가 하나님의 백성에게 남아 있도다.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },

  // -----------------------------------------------------------
  // v_379  시편 29:11
  // -----------------------------------------------------------
  {
    verse_id: 'v_379',
    verse_short_ko: '여호와께서 자기 백성에게 힘을 주심이여, 여호와께서 자기 백성에게 평강의 복을 주시리로다.',
    verse_full_ko:
      '여호와께서 자기 백성에게 힘을 주심이여, 여호와께서 자기 백성에게 평강의 복을 주시리로다.',
    reference: '시편 29:11',
    book: '시편',
    chapter: 29,
    verse: 11,
    mode: 'wind_down',
    theme: 'peace,rest,gratitude',
    mood: 'calm,cozy',
    season: 'all',
    weather: 'any',
    interpretation:
      '천둥과 폭풍을 묘사한 장엄한 시편의 마지막 구절이야.\n온 세상을 다스리시는 하나님이 마지막으로 하시는 일은 자기 백성에게 힘과 평강을 주시는 거야.\n우주를 움직이시는 그분이 오늘 밤 네게도 평강을 주시겠다고 하셔.',
    application:
      '오늘 하루를 마치며 이 말을 천천히 읽어봐. "여호와가 나에게 평강의 복을 주신다." 그리고 자.',
    curated: 'TRUE',
    status: 'active',
    alarm_top_ko: '여호와께서 자기 백성에게 평강의 복을 주시리로다.',
    notes: 'wind_down Zone 2026-04-24 추가',
  },
];

// ============================================================
// 자체 검증
// ============================================================
function validateVerses(verses) {
  const errors = [];
  const forbiddenTone = ['기억해\\.', '반드시', '해야 합니다', '하십시오', '명심', '해야 한다'];
  const forbiddenLang = ['히브리어', '헬라어', '그리스어'];

  verses.forEach((v) => {
    const id = v.verse_id;

    // 글자수
    if (v.verse_short_ko.length < 10 || v.verse_short_ko.length > 60)
      errors.push(`${id} verse_short_ko 길이 오류: ${v.verse_short_ko.length}자`);
    if (v.verse_full_ko.length < 20 || v.verse_full_ko.length > 200)
      errors.push(`${id} verse_full_ko 길이 오류: ${v.verse_full_ko.length}자`);
    if (v.interpretation.length < 80 || v.interpretation.length > 200)
      errors.push(`${id} interpretation 길이 오류: ${v.interpretation.length}자`);
    if (v.application.length < 30 || v.application.length > 100)
      errors.push(`${id} application 길이 오류: ${v.application.length}자`);

    // 어투
    forbiddenTone.forEach((pat) => {
      if (new RegExp(pat).test(v.interpretation) || new RegExp(pat).test(v.application))
        errors.push(`${id} 금지 어투 발견: ${pat}`);
    });

    // 원어 표기
    forbiddenLang.forEach((lang) => {
      if (v.interpretation.includes(lang) || v.application.includes(lang))
        errors.push(`${id} 원어 직접 표기 금지: ${lang}`);
    });

    // mode
    if (!v.mode.includes('wind_down'))
      errors.push(`${id} mode 오류: ${v.mode}`);

    // curated / status
    if (v.curated !== 'TRUE') errors.push(`${id} curated 오류`);
    if (v.status !== 'active') errors.push(`${id} status 오류`);
  });

  return errors;
}

// ============================================================
// Sheets 업로드
// 컬럼 순서: A~Q + R(usage_count) + S(cooldown) + T(last_shown) + U(show_count)
//            + V(alarm_top_ko) + W~Z(수식, 빈값) + AA(question, 빈값)
//            + AB~AG(len_*, 수식, 빈값)
// ============================================================
function buildRow(v) {
  return [
    v.verse_id,           // A
    v.verse_short_ko,     // B
    v.verse_full_ko,      // C
    v.reference,          // D
    v.book,               // E
    v.chapter,            // F
    v.verse,              // G
    v.mode,               // H
    v.theme,              // I
    v.mood,               // J
    v.season,             // K
    v.weather,            // L
    v.interpretation,     // M
    v.application,        // N
    v.curated,            // O
    v.status,             // P
    v.notes || '',        // Q
    0,                    // R usage_count
    '',                   // S cooldown_days
    '',                   // T last_shown
    0,                    // U show_count
    v.alarm_top_ko || '', // V alarm_top_ko
    // W~Z contemplation_* 수식 자동 — 빈값
    '', '', '', '',
    // AA question — 빈값 (별도 생성 예정)
    '',
    // AB~AG len_* 수식 자동 — 빈값
    '', '', '', '', '', '',
  ];
}

async function main() {
  // 1. 자체 검증
  console.log('=== 자체 검증 시작 ===');
  const errors = validateVerses(verses);
  if (errors.length > 0) {
    console.error('검증 실패:');
    errors.forEach((e) => console.error(' -', e));
    process.exit(1);
  }
  console.log(`검증 통과: ${verses.length}개 구절`);

  // 2. Sheets 업로드
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  const rows = verses.map(buildRow);

  const response = await sheets.spreadsheets.values.append({
    spreadsheetId: SPREADSHEET_ID,
    range: 'VERSES!A1',
    valueInputOption: 'USER_ENTERED',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  });

  console.log('=== 업로드 완료 ===');
  console.log(`추가된 행: ${response.data.updates.updatedRows}행`);
  console.log(`범위: ${response.data.updates.updatedRange}`);

  // 3. 요약 출력
  console.log('\n=== 생성 구절 목록 ===');
  verses.forEach((v) => {
    console.log(`${v.verse_id} [${v.reference}] ${v.verse_short_ko.substring(0, 30)}...`);
    console.log(`  interpretation: ${v.interpretation.length}자`);
    console.log(`  application: ${v.application.length}자`);
  });
}

main().catch((err) => {
  console.error('오류:', err.message);
  process.exit(1);
});

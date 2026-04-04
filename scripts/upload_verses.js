/**
 * DailyVerse — Firestore 말씀/이미지 데이터 업로드 스크립트 (REST API 방식)
 * v6.0: 8 Zone 시스템 반영 (deep_dark/first_light/rise_ignite/peak_mode/recharge/second_wind/golden_hour/wind_down)
 * firebase login 완료 후 실행: node upload_verses.js
 *
 * mode 값 (8 Zone):
 *   deep_dark    00:00–03:00  🌑 Deep Dark
 *   first_light  03:00–06:00  🌒 First Light
 *   rise_ignite  06:00–09:00  🌅 Rise & Ignite
 *   peak_mode    09:00–12:00  ⚡ Peak Mode
 *   recharge     12:00–15:00  ☀️ Recharge
 *   second_wind  15:00–18:00  🌤 Second Wind
 *   golden_hour  18:00–21:00  🌇 Golden Hour
 *   wind_down    21:00–24:00  🌙 Wind Down
 *   all          모든 시간대
 */

const https = require('https');
const fs = require('fs');
const os = require('os');
const path = require('path');

const PROJECT_ID = 'dailyverse-9260d';

// Firebase CLI 토큰 읽기
function getFirebaseToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  return config.tokens?.access_token;
}

// Firestore REST API로 문서 업로드
function firestoreSet(docPath, data, token) {
  return new Promise((resolve, reject) => {
    const fields = {};
    for (const [key, value] of Object.entries(data)) {
      if (value === null || value === undefined) continue;
      if (typeof value === 'string') {
        fields[key] = { stringValue: value };
      } else if (typeof value === 'boolean') {
        fields[key] = { booleanValue: value };
      } else if (typeof value === 'number') {
        if (Number.isInteger(value)) {
          fields[key] = { integerValue: String(value) };
        } else {
          fields[key] = { doubleValue: value };
        }
      } else if (Array.isArray(value)) {
        fields[key] = {
          arrayValue: {
            values: value.map(v => ({ stringValue: String(v) }))
          }
        };
      } else if (typeof value === 'object') {
        // 중첩 객체 (translations 등)
        const nestedFields = {};
        for (const [nk, nv] of Object.entries(value)) {
          if (nv !== null && nv !== undefined) {
            nestedFields[nk] = { stringValue: String(nv) };
          }
        }
        fields[key] = { mapValue: { fields: nestedFields } };
      }
    }

    const body = JSON.stringify({ fields });
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;

    const options = {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    const [host, ...pathParts] = url.replace('https://', '').split('/');
    const reqPath = '/' + pathParts.join('/');

    const req = https.request({ hostname: host, path: reqPath, ...options }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) resolve(data);
        else reject(new Error(`HTTP ${res.statusCode}: ${data.substring(0, 200)}`));
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ─── 말씀 데이터 (v5.1: cooldown_days, last_shown, show_count, translations, notes 필드 추가) ───

const verses = [
  {
    verse_id: "v_001",
    text_ko: "두려워하지 말라 내가 너와 함께 함이라",
    text_full_ko: "두려워하지 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라 내가 너를 굳세게 하리라 참으로 너를 도와 주리라",
    reference: "이사야 41:10", book: "이사야", chapter: 41, verse: 10,
    mode: ["rise_ignite"], theme: ["hope", "courage"], mood: ["bright", "dramatic"],
    season: ["all"], weather: ["any"],
    interpretation: "하나님이 직접 함께하겠다고 약속하신 말씀. 두려움이 찾아올 때 이 약속을 붙잡으라는 메시지",
    application: "오늘 걱정되는 일이 있다면 혼자가 아님을 기억해. 이 말씀을 오늘 하루의 닻으로 삼아봐",
    notes: "히브리어 '알 티라' — '두려워 말라'는 구약에서 365회 등장하는 하나님의 가장 많은 명령",
    translations: { ko_nkrv: "두려워하지 말라 내가 너와 함께 함이라" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  {
    verse_id: "v_002",
    text_ko: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
    text_full_ko: "여호와는 나의 목자시니 내게 부족함이 없으리로다 그가 나를 푸른 풀밭에 누이시며 쉴 만한 물 가로 인도하시는도다 내 영혼을 소생시키시고",
    reference: "시편 23:1-2", book: "시편", chapter: 23, verse: 1,
    mode: ["golden_hour"], theme: ["peace", "comfort"], mood: ["calm", "cozy"],
    season: ["all"], weather: ["rainy", "cloudy"],
    interpretation: "목자가 양을 돌보듯 하나님이 나의 모든 필요를 채우신다는 신뢰의 고백",
    application: "오늘 하루 부족하고 지쳤다면 이 말씀 앞에서 내려놓아봐. 채워주시는 분이 계셔",
    notes: "시편 23편 — 다윗이 목동이었던 자신의 경험으로 하나님과의 관계를 묘사",
    translations: { ko_nkrv: "여호와는 나의 목자시니 내게 부족함이 없으리로다" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  {
    verse_id: "v_003",
    text_ko: "담대하라 내가 세상을 이기었노라",
    text_full_ko: "세상에서는 너희가 환난을 당하나 담대하라 내가 세상을 이기었노라 이것을 너희에게 이르는 것은 너희로 내 안에서 평안을 누리게 하려 함이라",
    reference: "요한복음 16:33", book: "요한복음", chapter: 16, verse: 33,
    mode: ["rise_ignite", "peak_mode"], theme: ["courage", "strength"], mood: ["dramatic", "warm"],
    season: ["all"], weather: ["any"],
    interpretation: "예수님이 이미 세상을 이기셨기에 우리도 담대할 수 있다는 선언",
    application: "오늘 버거운 상황이 있다면 기억해. 이미 이긴 싸움 안에 네가 서 있어",
    notes: "κεκοσμηκα(케코스미카) — 완료형. 이미 완전히 이겼다는 뜻",
    translations: { ko_nkrv: "담대하라 내가 세상을 이기었노라" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  {
    verse_id: "v_004",
    text_ko: "주의 말씀은 내 발에 등이요 내 길에 빛이니이다",
    text_full_ko: "주의 말씀은 내 발에 등이요 내 길에 빛이니이다 주의 의로운 규례들을 지키기로 맹세하고 굳게 정하였나이다",
    reference: "시편 119:105", book: "시편", chapter: 119, verse: 105,
    mode: ["rise_ignite"], theme: ["wisdom", "hope"], mood: ["bright", "calm"],
    season: ["all"], weather: ["any"],
    interpretation: "하나님의 말씀이 삶의 방향을 밝혀주는 빛이 된다는 고백",
    application: "오늘 어떤 결정 앞에 서 있다면, 말씀 안에서 방향을 찾아봐. 빛은 이미 켜져 있어",
    notes: "등(ner) — 발 하나 앞을 비추는 작은 손등. 전체 길이 아닌 한 걸음씩의 인도",
    translations: { ko_nkrv: "주의 말씀은 내 발에 등이요 내 길에 빛이니이다" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  {
    verse_id: "v_005",
    text_ko: "너희 염려를 다 주께 맡기라",
    text_full_ko: "너희 염려를 다 주께 맡기라 이는 그가 너희를 돌보심이라 근신하라 깨어라 너희 대적 마귀가 우는 사자 같이 두루 다니며 삼킬 자를 찾나니",
    reference: "베드로전서 5:7", book: "베드로전서", chapter: 5, verse: 7,
    mode: ["golden_hour"], theme: ["peace", "rest"], mood: ["calm", "cozy"],
    season: ["all"], weather: ["rainy", "cloudy"],
    interpretation: "염려를 스스로 해결하려 하지 말고 하나님께 던져놓으라는 적극적 권면",
    application: "오늘 하루 머릿속에 무거운 게 있다면 억지로 안고 있지 마. 내려놓는 것도 믿음이야",
    notes: "ἐπιρίπτω(에피립토) — '내던지다'. 가만히 맡기는 게 아니라 힘껏 던지는 행위",
    translations: { ko_nkrv: "너희 염려를 다 주께 맡기라" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  {
    verse_id: "v_006",
    text_ko: "내가 능력 주시는 자 안에서 모든 것을 할 수 있느니라",
    text_full_ko: "내가 비천에 처할 줄도 알고 풍부에 처할 줄도 알아 모든 일 곧 배부름과 배고픔과 풍부와 궁핍에도 처할 줄 아는 일체의 비결을 배웠노라 내가 능력 주시는 자 안에서 모든 것을 할 수 있느니라",
    reference: "빌립보서 4:13", book: "빌립보서", chapter: 4, verse: 13,
    mode: ["rise_ignite", "peak_mode"], theme: ["strength", "courage"], mood: ["dramatic", "warm"],
    season: ["all"], weather: ["any"],
    interpretation: "자기 능력이 아닌 그리스도 안에서 주어지는 힘으로 살아간다는 선언",
    application: "오늘 벅차게 느껴지는 일이 있어? 네 힘으로 하려 하지 말고, 능력 주시는 분께 연결돼봐",
    notes: "ἐνδυναμοῦντί(엔뒤나무운티) — '능력을 계속 불어넣으시는 분' 현재진행형",
    translations: { ko_nkrv: "내가 능력 주시는 자 안에서 모든 것을 할 수 있느니라" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  {
    verse_id: "v_007",
    text_ko: "항상 기뻐하라 쉬지 말고 기도하라 범사에 감사하라",
    text_full_ko: "항상 기뻐하라 쉬지 말고 기도하라 범사에 감사하라 이것이 그리스도 예수 안에서 너희를 향하신 하나님의 뜻이니라",
    reference: "데살로니가전서 5:16-18", book: "데살로니가전서", chapter: 5, verse: 16,
    mode: ["rise_ignite"], theme: ["gratitude", "renewal"], mood: ["bright", "warm"],
    season: ["all"], weather: ["any"],
    interpretation: "기쁨·기도·감사는 감정이 아니라 의지적 선택이자 훈련이라는 메시지",
    application: "오늘 하루 기분이 어떻든 상관없어. 기뻐하는 것, 감사하는 것은 선택할 수 있어",
    notes: "헬라어 명령형 현재형 — 한 번이 아니라 지속적으로 기뻐하고 기도하고 감사하라는 뜻",
    translations: { ko_nkrv: "항상 기뻐하라 쉬지 말고 기도하라 범사에 감사하라" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  {
    verse_id: "v_008",
    text_ko: "여호와를 기뻐하라 그가 네 마음의 소원을 이루어 주시리로다",
    text_full_ko: "여호와를 의뢰하고 선을 행하라 땅에 머무는 동안 그의 성실을 먹을 거리로 삼을지어다 또 여호와를 기뻐하라 그가 네 마음의 소원을 네게 이루어 주시리로다",
    reference: "시편 37:4", book: "시편", chapter: 37, verse: 4,
    mode: ["golden_hour"], theme: ["hope", "gratitude"], mood: ["calm", "warm"],
    season: ["spring", "summer"], weather: ["any"],
    interpretation: "소원 성취의 조건이 '여호와를 기뻐하는 것'이라는 역설적 구조",
    application: "원하는 게 있어? 그걸 붙잡기 전에 먼저 하나님 안에서 기쁨을 찾아봐",
    notes: "히브리어 '에노그 알 야훼' — 하나님 안에서 즐거움을 찾으라, 소원 자체보다 하나님이 먼저",
    translations: { ko_nkrv: "여호와를 기뻐하라 그가 네 마음의 소원을 이루어 주시리로다" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  // v5.1 신규: 새벽(dawn) 모드 말씀
  {
    verse_id: "v_009",
    text_ko: "내가 새벽 날개를 치며 바다 끝에 거할지라도",
    text_full_ko: "내가 새벽 날개를 치며 바다 끝에 거할지라도 거기서도 주의 손이 나를 인도하시며 주의 오른손이 나를 붙드시리이다",
    reference: "시편 139:9-10", book: "시편", chapter: 139, verse: 9,
    mode: ["first_light"], theme: ["stillness", "faith"], mood: ["serene", "calm"],
    season: ["all"], weather: ["any"],
    interpretation: "어디에 있든, 어떤 시간이든 하나님의 손이 함께한다는 확신의 고백",
    application: "잠 못 드는 이 시간에도 하나님이 붙드심을 기억해. 새벽도 주의 영역이야",
    notes: "새벽 날개 — 이른 새벽 동이 틀 때 빛이 퍼지는 모습을 날개로 표현",
    translations: { ko_nkrv: "내가 새벽 날개를 치며 바다 끝에 거할지라도" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  },
  {
    verse_id: "v_010",
    text_ko: "새벽에 주께서 내 기도를 들으시리니",
    text_full_ko: "여호와여 아침에 주께서 나의 소리를 들으시리니 아침에 내가 주께 기도하고 바라리이다",
    reference: "시편 5:3", book: "시편", chapter: 5, verse: 3,
    mode: ["first_light", "rise_ignite"], theme: ["stillness", "grace"], mood: ["serene", "calm"],
    season: ["all"], weather: ["any"],
    interpretation: "새벽/아침에 올리는 기도를 하나님이 들으신다는 다윗의 습관과 확신",
    application: "지금 이 시간, 말하지 않아도 하나님은 네 마음을 알고 계셔. 그냥 나와봐",
    notes: "히브리어 보케르 — 새벽, 동이 트는 시간. 다윗의 기도 습관을 보여주는 구절",
    translations: { ko_nkrv: "여호와여 아침에 주께서 나의 소리를 들으시리니" },
    curated: true, status: "active", usage_count: 0,
    last_shown: null, show_count: 0, cooldown_days: 7
  }
];

// ─── 이미지 데이터 (v5.1: text_position, text_color, is_sacred_safe, avoid_themes 필드 추가) ───

// ─── 이미지 URL: Google Drive 직접 다운로드 URL ───────────────────────────────
// Google Drive 공유 파일을 직접 이미지로 서브하는 URL 형식:
// https://drive.google.com/uc?export=view&id=FILE_ID
// - 파일을 "링크가 있는 모든 사용자" 공유 설정 필요
// - iOS URLSession에서 직접 JPEG 로드 확인 완료

const images = [
  {
    image_id: "img_001",
    filename: "gdrive_img_001.jpg",
    storage_url: "https://drive.google.com/uc?export=view&id=1PUe_LgBqgmpPwf70wgkJXg7g9DTKXyFA",
    source: "Google Drive (Genspark Pro)", source_url: "", license: "Commercial",
    mode: ["rise_ignite", "peak_mode", "recharge", "golden_hour"],
    theme: ["hope", "courage", "wisdom"],
    mood: ["bright", "dramatic"],
    season: ["all"], weather: ["any"],
    tone: "bright",
    text_position: "bottom",
    text_color: "light",
    is_sacred_safe: true,
    avoid_themes: [],
    status: "active"
  },
  {
    image_id: "img_002",
    filename: "gdrive_img_002.jpg",
    storage_url: "https://drive.google.com/uc?export=view&id=1Jv38mELMaL9kFwVC2o7F9vToMPtlrSgp",
    source: "Google Drive (Genspark Pro)", source_url: "", license: "Commercial",
    mode: ["rise_ignite", "peak_mode", "recharge", "golden_hour"],
    theme: ["strength", "renewal", "peace"],
    mood: ["serene", "calm"],
    season: ["all"], weather: ["any"],
    tone: "mid",
    text_position: "bottom",
    text_color: "light",
    is_sacred_safe: true,
    avoid_themes: [],
    status: "active"
  },
  {
    image_id: "img_003",
    filename: "gdrive_img_003.jpg",
    storage_url: "https://drive.google.com/uc?export=view&id=1pouIqKzr5deSdJeJmk9SYRkLo7WLc3JD",
    source: "Google Drive (Genspark Pro)", source_url: "", license: "Commercial",
    mode: ["first_light", "rise_ignite", "golden_hour"],
    theme: ["stillness", "faith", "reflection"],
    mood: ["serene", "calm", "cozy"],
    season: ["all"], weather: ["any"],
    tone: "dark",
    text_position: "center",
    text_color: "light",
    is_sacred_safe: true,
    avoid_themes: [],
    status: "active"
  },
  {
    image_id: "img_004",
    filename: "gdrive_img_004.jpg",
    storage_url: "https://drive.google.com/uc?export=view&id=1IpjnaNBUKlt1fH9V-NLqEcWHHM3NjosM",
    source: "Google Drive (Genspark Pro)", source_url: "", license: "Commercial",
    mode: ["all"],
    theme: ["grace", "comfort", "rest"],
    mood: ["serene", "warm"],
    season: ["all"], weather: ["any"],
    tone: "mid",
    text_position: "bottom",
    text_color: "light",
    is_sacred_safe: true,
    avoid_themes: [],
    status: "active"
  },
  // img_005, img_006: Unsplash 유지 (추가 이미지 제공 시 교체 예정)
  {
    image_id: "img_005",
    filename: "unsplash_sea_cliff.jpg",
    storage_url: "https://images.unsplash.com/photo-1483728642387-6c3bdd6c93e5?w=1200&q=80",
    source: "Unsplash (CC0)", source_url: "", license: "CC0",
    mode: ["rise_ignite", "peak_mode"],
    theme: ["wisdom", "focus", "courage"],
    mood: ["dramatic", "bright"],
    season: ["all"], weather: ["sunny", "any"],
    tone: "bright",
    text_position: "bottom",
    text_color: "light",
    is_sacred_safe: true,
    avoid_themes: [],
    status: "active"
  },
  {
    image_id: "img_006",
    filename: "unsplash_night_stars.jpg",
    storage_url: "https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=1200&q=80",
    source: "Unsplash (CC0)", source_url: "", license: "CC0",
    mode: ["first_light", "wind_down"],
    theme: ["stillness", "hope", "grace"],
    mood: ["serene", "calm"],
    season: ["all"], weather: ["any"],
    tone: "dark",
    text_position: "center",
    text_color: "light",
    is_sacred_safe: true,
    avoid_themes: [],
    status: "active"
  }
];

async function uploadImages(token) {
  console.log(`\n🖼️  이미지 ${images.length}개 업로드 시작...\n`);
  let success = 0, failed = 0;

  for (const image of images) {
    const { image_id } = image;
    try {
      await firestoreSet(`images/${image_id}`, image, token);
      console.log(`✅ ${image_id}: ${image.filename}`);
      success++;
    } catch (err) {
      console.error(`❌ ${image_id} 실패: ${err.message.substring(0, 100)}`);
      failed++;
    }
  }

  console.log(`\n✨ 이미지 완료! 성공: ${success}개, 실패: ${failed}개`);
}

async function uploadVerses(token) {
  console.log(`\n🚀 DailyVerse 말씀 ${verses.length}개 Firestore 업로드 시작...\n`);
  let success = 0, failed = 0;

  for (const verse of verses) {
    const { verse_id } = verse;
    try {
      await firestoreSet(`verses/${verse_id}`, verse, token);
      console.log(`✅ ${verse_id}: ${verse.text_ko.substring(0, 25)}...`);
      success++;
    } catch (err) {
      console.error(`❌ ${verse_id} 실패: ${err.message.substring(0, 100)}`);
      failed++;
    }
  }

  console.log(`\n✨ 완료! 성공: ${success}개, 실패: ${failed}개`);
}

async function main() {
  const token = getFirebaseToken();
  if (!token) {
    console.error('❌ Firebase 토큰을 찾을 수 없습니다. firebase login을 먼저 실행하세요.');
    process.exit(1);
  }
  await uploadVerses(token);
  await uploadImages(token);
  console.log(`\n🔗 Firestore 확인:`);
  console.log(`   https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
}

main();

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 글자수 기준
const CHAR_LIMITS = {
  verse_short_ko:                { min: 20, max: 60 },
  verse_full_ko:                 { min: 40, max: 120 },
  interpretation:                { min: 102, max: 154 },
  application:                   { min: 49, max: 73 },
  alarm_top_ko:                  { min: 15, max: 35 },
  contemplation_ko:              { min: 50, max: 200 },
  contemplation_interpretation:  { min: 80, max: 150 },
  contemplation_appliance:       { min: 40, max: 80 },
  question:                      { min: 40, max: 80 },
};

// 금지 말투
const FORBIDDEN_TONE_PATTERNS = [
  '습니다', '합니다', '입니다', '하십시오', '해야 한다', '해야 해'
];

// 원어 표기 패턴 (히브리어/헬라어 키워드 + 원어 단어 그대로 표기)
// 한글/영문/숫자/공백/문장부호를 제외한 문자 (예: נֶפֶשׁ, ἀγάπη 등)
const ORIGINAL_LANGUAGE_KEYWORDS = [
  '히브리어', '헬라어', '아람어', '코이네', '아라믹',
  '히브리 원어', '헬라 원어', '그리스어'
];

// 원어 문자 패턴: 히브리 문자(U+0590-U+05FF), 그리스 문자(U+0370-U+03FF, U+1F00-U+1FFF)
const ORIGINAL_SCRIPT_REGEX = /[\u0590-\u05FF\u0370-\u03FF\u1F00-\u1FFF]/;

function checkCharLength(text, fieldName) {
  const limits = CHAR_LIMITS[fieldName];
  if (!limits) return null;
  const len = text.length;
  if (len < limits.min) return { type: 'too_short', len, min: limits.min, max: limits.max };
  if (len > limits.max) return { type: 'too_long', len, min: limits.min, max: limits.max };
  return null;
}

function checkForbiddenTone(text) {
  const found = [];
  for (const pattern of FORBIDDEN_TONE_PATTERNS) {
    if (text.includes(pattern)) found.push(pattern);
  }
  return found;
}

function checkOriginalLanguage(text) {
  const found = [];
  for (const kw of ORIGINAL_LANGUAGE_KEYWORDS) {
    if (text.includes(kw)) found.push(kw);
  }
  if (ORIGINAL_SCRIPT_REGEX.test(text)) found.push('원어문자(히브리/헬라어 스크립트)');
  return found;
}

function excerpt(text, len = 30) {
  if (!text) return '';
  return text.slice(0, len) + (text.length > len ? '...' : '');
}

async function main() {
  const snapshot = await db.collection('verses').get();
  const verses = [];
  snapshot.forEach(doc => {
    verses.push({ id: doc.id, ...doc.data() });
  });

  verses.sort((a, b) => a.id.localeCompare(b.id));

  // 결과 저장
  const fieldViolations = {};
  for (const field of Object.keys(CHAR_LIMITS)) {
    fieldViolations[field] = [];
  }
  const toneViolations = [];
  const langViolations = [];

  for (const verse of verses) {
    const vid = verse.id;

    // 글자수 검사 (9개 필드)
    for (const field of Object.keys(CHAR_LIMITS)) {
      const text = verse[field];
      if (text === undefined || text === null || text === '') {
        fieldViolations[field].push({
          id: vid,
          issue: 'missing',
          text: '(필드 없음)'
        });
        continue;
      }
      const result = checkCharLength(text, field);
      if (result) {
        fieldViolations[field].push({
          id: vid,
          issue: result.type,
          len: result.len,
          min: result.min,
          max: result.max,
          text: excerpt(text, 30)
        });
      }
    }

    // 말투 + 원어 표기 검사 대상 필드
    const toneCheckFields = [
      'interpretation', 'application',
      'contemplation_ko', 'contemplation_interpretation', 'contemplation_appliance',
      'question', 'alarm_top_ko'
    ];

    for (const field of toneCheckFields) {
      const text = verse[field];
      if (!text) continue;

      const forbiddenTones = checkForbiddenTone(text);
      if (forbiddenTones.length > 0) {
        toneViolations.push({
          id: vid,
          field,
          patterns: forbiddenTones,
          text: excerpt(text, 40)
        });
      }

      const langFound = checkOriginalLanguage(text);
      if (langFound.length > 0) {
        langViolations.push({
          id: vid,
          field,
          patterns: langFound,
          text: excerpt(text, 40)
        });
      }
    }
  }

  // 출력
  console.log('=== 필드별 위반 현황 ===\n');

  let totalFieldViolCount = 0;

  for (const field of Object.keys(CHAR_LIMITS)) {
    const viols = fieldViolations[field];
    console.log(`[${field}] 위반: ${viols.length}개`);
    for (const v of viols) {
      if (v.issue === 'missing') {
        console.log(`  - ${v.id}: (필드 없음)`);
      } else if (v.issue === 'too_short') {
        console.log(`  - ${v.id} (${v.len}자, 최소 ${v.min}자): "${v.text}" ← 기준 미달`);
      } else if (v.issue === 'too_long') {
        console.log(`  - ${v.id} (${v.len}자, 최대 ${v.max}자): "${v.text}" ← 길이 초과`);
      }
    }
    totalFieldViolCount += viols.length;
    console.log('');
  }

  console.log(`[말투(설교조)] 위반: ${toneViolations.length}건`);
  for (const v of toneViolations) {
    console.log(`  - ${v.id} [${v.field}]: 감지된 패턴 "${v.patterns.join(', ')}" → "${v.text}"`);
  }
  console.log('');

  console.log(`[원어 표기] 위반: ${langViolations.length}건`);
  for (const v of langViolations) {
    console.log(`  - ${v.id} [${v.field}]: 감지된 패턴 "${v.patterns.join(', ')}" → "${v.text}"`);
  }
  console.log('');

  // 위반 있는 verse_id 수집
  const violatingIds = new Set();
  for (const viols of Object.values(fieldViolations)) {
    for (const v of viols) violatingIds.add(v.id);
  }
  for (const v of toneViolations) violatingIds.add(v.id);
  for (const v of langViolations) violatingIds.add(v.id);

  console.log('=== 요약 ===');
  console.log(`총 검사: ${verses.length}개 문서`);
  console.log(`위반 없음: ${verses.length - violatingIds.size}개`);
  console.log(`위반 있음: ${violatingIds.size}개 (문서 기준)`);
  console.log('필드별:');
  for (const field of Object.keys(CHAR_LIMITS)) {
    const count = fieldViolations[field].length;
    if (count > 0) console.log(`  ${field}: ${count}건`);
  }
  if (toneViolations.length > 0) console.log(`  말투(설교조): ${toneViolations.length}건`);
  if (langViolations.length > 0) console.log(`  원어 표기: ${langViolations.length}건`);

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });

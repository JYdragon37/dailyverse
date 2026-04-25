/**
 * 따옴표+음역 패턴 상세 분석
 * content-rules.json 기준: "X"는 형태의 원어 음역 직접 표기 위반 여부 판단
 *
 * 판단 기준:
 * - 성경 본문을 그대로 따옴표 인용 → 위반 아님 (본문 인용은 정상)
 * - 원어 음역 단어를 따옴표로 묶어 설명 → 위반
 * - 짧은 단어(8자 이하)이면서 '~뜻이야', '~의미야', '~나타내' 등과 함께 등장 → 위반 의심
 */

const data = require('/tmp/verses_check.json');

// 따옴표 패턴 (큰따옴표, 스마트 따옴표 포함)
function extractQuotedPhrases(text) {
  const results = [];
  // 다양한 따옴표 형태
  const patterns = [
    /[""]([가-힣\w ]+)[""](는|이란|이라는|은|이)/g,
    /'([가-힣\w ]+)'(는|이란|이라는|은|이)/g,
  ];
  patterns.forEach(pat => {
    let m;
    while ((m = pat.exec(text)) !== null) {
      results.push({
        quoted: m[1],
        suffix: m[2],
        context: text.substring(Math.max(0, m.index - 15), m.index + m[0].length + 20),
        index: m.index
      });
    }
  });
  return results;
}

// 원어 음역인지 성경 본문 인용인지 휴리스틱 판단
function isOriginalLanguageTranslit(quoted, context) {
  // 2~6자이면서 성경 본문에 없는 단어면 원어 음역 의심
  // 단, 성경 본문에 직접 등장하는 구절은 정상 인용

  // 짧은 단어(6자 이하) + 뜻/의미 설명이 뒤따르면 의심
  const explanationKeywords = ['뜻이야', '의미야', '뜻을', '의미를', '뜻은', '의미는', '나타내', '표현이야'];
  const hasExplanation = explanationKeywords.some(k => context.includes(k));

  // 성경 본문 인용은 보통 10자 이상 (구절이 길다)
  if (quoted.length <= 6 && hasExplanation) return 'HIGH_RISK';
  if (quoted.length <= 10 && hasExplanation) return 'MEDIUM_RISK';
  return 'LIKELY_OK'; // 긴 인용구는 본문 인용으로 추정
}

console.log('=== 따옴표 인용 패턴 상세 분석 ===\n');

const highRisk = [];
const medRisk = [];

data.forEach(v => {
  const interp = v.interpretation || '';
  const app = v.application || '';

  [interp, app].forEach((text, fieldIdx) => {
    const field = fieldIdx === 0 ? 'interpretation' : 'application';
    const phrases = extractQuotedPhrases(text);
    phrases.forEach(p => {
      const risk = isOriginalLanguageTranslit(p.quoted, p.context);
      if (risk === 'HIGH_RISK') {
        highRisk.push({id: v.verse_id, ref: v.reference, field, quoted: p.quoted, context: p.context});
      } else if (risk === 'MEDIUM_RISK') {
        medRisk.push({id: v.verse_id, ref: v.reference, field, quoted: p.quoted, context: p.context});
      }
    });
  });
});

console.log('HIGH_RISK (원어 음역 위반 강한 의심):');
if (highRisk.length === 0) console.log('  없음');
highRisk.forEach(r => {
  console.log(`  ${r.id} ${r.ref} [${r.field}] | 따옴표 단어: "${r.quoted}" | ${r.context}`);
});

console.log('\nMEDIUM_RISK (성경 본문 인용으로 추정되나 확인 필요):');
if (medRisk.length === 0) console.log('  없음');
medRisk.forEach(r => {
  console.log(`  ${r.id} ${r.ref} [${r.field}] | 따옴표 단어(${r.quoted.length}자): "${r.quoted}" | ${r.context}`);
});

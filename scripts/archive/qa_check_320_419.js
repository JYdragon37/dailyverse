/**
 * qa_check_320_419.js
 * v_320~v_419 구절 품질 검수
 */

const data = require('/tmp/verses_check.json');

// =====================================================
// 1. verse_short_ko 길이 점검
// =====================================================
console.log('\n=== [1] verse_short_ko 길이 점검 ===');
const shortOver35 = [];
const shortOver50 = [];
data.forEach(v => {
  const len = v.verse_short_ko.length;
  if (len > 50) shortOver50.push({id: v.verse_id, ref: v.reference, len, text: v.verse_short_ko});
  else if (len > 35) shortOver35.push({id: v.verse_id, ref: v.reference, len, text: v.verse_short_ko});
});
console.log('35자 초과(경고):', shortOver35.length + '건');
shortOver35.forEach(v => console.log('  ', v.id, v.ref, v.len+'자', '|', v.text));
console.log('50자 초과(위반):', shortOver50.length + '건');
shortOver50.forEach(v => console.log('  ', v.id, v.ref, v.len+'자', '|', v.text));

// =====================================================
// 2. application/interpretation 금지 어투
// =====================================================
console.log('\n=== [2] 금지 어투 패턴 ===');
const forbiddenTone = [
  { pat: /기억해\./g, name: '기억해. (마침표 단독)' },
  { pat: /반드시/g, name: '반드시' },
  { pat: /해야 합니다/g, name: '해야 합니다' },
  { pat: /하십시오/g, name: '하십시오' },
  { pat: /명심/g, name: '명심' },
  { pat: /해야 한다/g, name: '해야 한다' },
  { pat: /잊지 마세요/g, name: '잊지 마세요' },
  { pat: /잊지 말아야/g, name: '잊지 말아야' },
];
const toneIssues = [];
data.forEach(v => {
  forbiddenTone.forEach(ft => {
    ft.pat.lastIndex = 0;
    const inApp = (v.application || '').match(ft.pat);
    ft.pat.lastIndex = 0;
    const inInterp = (v.interpretation || '').match(ft.pat);
    ft.pat.lastIndex = 0;
    if (inApp) toneIssues.push({id: v.verse_id, ref: v.reference, field: 'application', pattern: ft.name, text: v.application});
    if (inInterp) toneIssues.push({id: v.verse_id, ref: v.reference, field: 'interpretation', pattern: ft.name, text: v.interpretation.substring(0,80)});
  });
});
if (toneIssues.length === 0) {
  console.log('  이상 없음');
} else {
  toneIssues.forEach(t => console.log(' ', t.id, t.ref, '['+t.field+']', '"'+t.pattern+'"', '|', t.text.substring(0,90)));
}

// =====================================================
// 3. 번영신학 위험 표현
// =====================================================
console.log('\n=== [3] 번영신학 위험 표현 ===');
const prosperityPatterns = [
  { pat: /하면 반드시/g, name: '하면 반드시' },
  { pat: /믿으면 다 된다/g, name: '믿으면 다 된다' },
  { pat: /믿으면.*이루어진다/g, name: '믿으면~이루어진다' },
  { pat: /순종하면.*이루어/g, name: '순종하면~이루어' },
  { pat: /하면.*이루어진다/g, name: '하면~이루어진다' },
  { pat: /하면.*반드시 받는다/g, name: '하면~반드시 받는다' },
  { pat: /기도하면.*반드시/g, name: '기도하면~반드시' },
  { pat: /믿음으로.*반드시 이루/g, name: '믿음으로~반드시 이루' },
  { pat: /복을 보장/g, name: '복을 보장' },
  { pat: /드리면.*돌아온다/g, name: '드리면~돌아온다' },
  { pat: /헌신하면.*복/g, name: '헌신하면~복' },
  { pat: /순종하면.*복 받/g, name: '순종하면~복 받' },
];
const prosperityIssues = [];
data.forEach(v => {
  const combined = (v.interpretation || '') + ' ' + (v.application || '');
  prosperityPatterns.forEach(pp => {
    pp.pat.lastIndex = 0;
    if (pp.pat.test(combined)) {
      pp.pat.lastIndex = 0;
      prosperityIssues.push({id: v.verse_id, ref: v.reference, pattern: pp.name, text: combined.substring(0,120)});
    }
    pp.pat.lastIndex = 0;
  });
});
const pUniq = [...new Map(prosperityIssues.map(i => [i.id + i.pattern, i])).values()];
if (pUniq.length === 0) {
  console.log('  이상 없음');
} else {
  pUniq.forEach(p => console.log(' ', p.id, p.ref, '"'+p.pattern+'"', '|', p.text));
}

// =====================================================
// 4. 원어 직접 표기
// =====================================================
console.log('\n=== [4] 원어 직접 표기 위반 ===');
const origLangPatterns = [
  { pat: /히브리어\s*['"']?\s*[가-힣]+/g, name: '히브리어+한글' },
  { pat: /헬라어\s*['"']?\s*[가-힣]+/g, name: '헬라어+한글' },
  { pat: /그리스어\s*['"']?\s*[가-힣]+/g, name: '그리스어+한글' },
];
const origIssues = [];
data.forEach(v => {
  const combined = (v.interpretation || '') + ' ' + (v.application || '');
  origLangPatterns.forEach(op => {
    op.pat.lastIndex = 0;
    const m = combined.match(op.pat);
    if (m) origIssues.push({id: v.verse_id, ref: v.reference, type: op.name, match: m[0]});
    op.pat.lastIndex = 0;
  });
  // "X"는 패턴 (따옴표+원어음역 설명)
  const quotePattern = /["""]([\uAC00-\uD7A3a-zA-Z\s]+)["""]는/g;
  let qm;
  while ((qm = quotePattern.exec(combined)) !== null) {
    origIssues.push({id: v.verse_id, ref: v.reference, type: '따옴표+음역', match: qm[0]});
  }
});
const oUniq = [...new Map(origIssues.map(i => [i.id + i.type, i])).values()];
if (oUniq.length === 0) {
  console.log('  이상 없음');
} else {
  oUniq.forEach(o => console.log(' ', o.id, o.ref, o.type, '|', o.match));
}

// =====================================================
// 5. interpretation 글자수 (80~200자)
// =====================================================
console.log('\n=== [5] interpretation 글자수 범위 (80~200자) ===');
const interpLenIssues = [];
data.forEach(v => {
  const len = (v.interpretation || '').length;
  if (len < 80 || len > 200) {
    interpLenIssues.push({id: v.verse_id, ref: v.reference, len, text: v.interpretation.substring(0,60)});
  }
});
if (interpLenIssues.length === 0) {
  console.log('  이상 없음');
} else {
  interpLenIssues.forEach(i => console.log(' ', i.id, i.ref, i.len+'자', '|', i.text));
}

// =====================================================
// 6. interpretation 4단계 구조 평가
// =====================================================
console.log('\n=== [6] interpretation 4단계 구조 평가 (2점 이하만 표시) ===');

function evalInterpretationStructure(v) {
  const text = v.interpretation || '';
  let score = 0;
  const missing = [];

  // ① 배경/맥락: 저자명, 상황 설명 키워드
  const bgKeywords = /바울|다윗|솔로몬|이사야|예레미야|모세|베드로|요한|야고보|예수|선지자|사도|포로|광야|전쟁|당시|그 시절|기록|배경|상황|처했|쓰여/;
  if (bgKeywords.test(text)) {
    score++;
  } else {
    missing.push('①배경');
  }

  // ② 원어/뉘앙스: 단어 의미 설명 (원어 표기 없이)
  const nuanceKeywords = /뜻은|의미는|뜻이|의미가|원래|본래|단어|표현|뉘앙스|깊은 뜻|담겨|담긴|뜻을|의미를|의미로/;
  if (nuanceKeywords.test(text)) {
    score++;
  } else {
    missing.push('②원어뉘앙스');
  }

  // ③ 오늘날 연결: 현재형 삶 연결 키워드
  const todayKeywords = /오늘|지금|우리|현대|일상|삶에|살아가|살면서|요즘|현실|매일|하루하루|우리에게|우리의/;
  if (todayKeywords.test(text)) {
    score++;
  } else {
    missing.push('③오늘연결');
  }

  // ④ Zone 맥락: 시간대/감성 키워드
  const zoneKeywords = /아침|저녁|밤|새벽|낮|오전|오후|하루|잠들기|눈을 뜨|시작하|마무리|쉬며|피곤|지친|고요|평온|활기/;
  if (zoneKeywords.test(text)) {
    score++;
  } else {
    missing.push('④Zone연결');
  }

  return { score, missing };
}

const structureIssues = [];
data.forEach(v => {
  const { score, missing } = evalInterpretationStructure(v);
  if (score <= 2) {
    structureIssues.push({
      id: v.verse_id, ref: v.reference, score, missing: missing.join(', '),
      text: (v.interpretation || '').substring(0, 80)
    });
  }
});

if (structureIssues.length === 0) {
  console.log('  2점 이하 구절 없음');
} else {
  structureIssues.forEach(s => console.log(' ', s.id, s.ref, s.score+'/4점', '누락:', s.missing, '|', s.text));
}
console.log('  총', structureIssues.length + '건 (2점 이하)');

// =====================================================
// 7. 내부 중복 (v_320~v_419 내부 reference 중복)
// =====================================================
console.log('\n=== [7] v_320~v_419 내부 reference 중복 ===');
const refMap = {};
data.forEach(v => {
  const r = v.reference;
  if (!refMap[r]) refMap[r] = [];
  refMap[r].push(v.verse_id);
});
let internalDupCount = 0;
Object.entries(refMap).forEach(([ref, ids]) => {
  if (ids.length > 1) {
    console.log(' ', ref, '->', ids.join(', '));
    internalDupCount++;
  }
});
if (internalDupCount === 0) console.log('  이상 없음');

// =====================================================
// 8. 기존 v_001~v_319와 reference 중복
// =====================================================
console.log('\n=== [8] 기존 v_001~v_319와 reference 중복 ===');
const allData = require('/tmp/verses_all.json');
const existingRefs = {};
allData.forEach(v => {
  const num = parseInt((v.verse_id || '').replace('v_', ''));
  if (num >= 1 && num <= 319) {
    const r = v.reference;
    if (!existingRefs[r]) existingRefs[r] = [];
    existingRefs[r].push(v.verse_id);
  }
});

// 특별 주의 구절 (요청에 명시됨)
const watchList = ['이사야 40:31', '시편 62:5', '잠언 16:9', '갈라디아서 6:9', '골로새서 3:23', '여호수아 1:9'];

const extDupIssues = [];
data.forEach(v => {
  const r = v.reference;
  if (existingRefs[r]) {
    const isWatch = watchList.some(w => r.includes(w.split(' ')[0]) && r.includes(w.split(' ')[1]));
    extDupIssues.push({id: v.verse_id, ref: r, existing: existingRefs[r].join(', '), isWatch});
  }
});

if (extDupIssues.length === 0) {
  console.log('  이상 없음');
} else {
  extDupIssues.sort((a, b) => (b.isWatch ? 1 : 0) - (a.isWatch ? 1 : 0));
  extDupIssues.forEach(e => {
    const flag = e.isWatch ? '[주의] ' : '';
    console.log(' ', flag + e.id, e.ref, '-> 기존:', e.existing);
  });
}

// =====================================================
// 9. application 글자수 (30~100자)
// =====================================================
console.log('\n=== [9] application 글자수 범위 (30~100자) ===');
const appLenIssues = [];
data.forEach(v => {
  const len = (v.application || '').length;
  if (len < 30 || len > 100) {
    appLenIssues.push({id: v.verse_id, ref: v.reference, len, text: v.application});
  }
});
if (appLenIssues.length === 0) {
  console.log('  이상 없음');
} else {
  appLenIssues.forEach(a => console.log(' ', a.id, a.ref, a.len+'자', '|', a.text));
}

// =====================================================
// 10. 개역개정 표현 혼용 체크
// =====================================================
console.log('\n=== [10] 개역개정 표현 혼용 의심 ===');
const gaeykPatterns = [
  { pat: /평안을 너희에게/g, name: '평안을 (→ 평강을)', ref: '요한복음 14:27' },
  { pat: /그를 믿는 자마다 멸망하지 않고/g, name: '그를/멸망하지 않고 (→ 저를/멸망치 않고)', ref: '요한복음 3:16' },
  { pat: /온 마음으로/g, name: '온 마음으로 (→ 전심으로)', ref: '예레미야 29:13 계열' },
  { pat: /평안한 집/g, name: '평안한 집 (→ 화평한 집)', ref: '이사야 32:18' },
  { pat: /조용한 쉴/g, name: '조용한 쉴 (→ 종용히 쉬는)', ref: '이사야 32:18' },
  { pat: /그들에게 이르시되/g, name: '그들에게 (→ 저희에게)', ref: '개역개정 인칭' },
];
const translationIssues = [];
data.forEach(v => {
  const fullKo = v.verse_full_ko || '';
  gaeykPatterns.forEach(gp => {
    gp.pat.lastIndex = 0;
    if (gp.pat.test(fullKo)) {
      gp.pat.lastIndex = 0;
      translationIssues.push({id: v.verse_id, ref: v.reference, pattern: gp.name, text: fullKo.substring(0, 80)});
    }
    gp.pat.lastIndex = 0;
  });
});
if (translationIssues.length === 0) {
  console.log('  이상 없음');
} else {
  translationIssues.forEach(t => console.log(' ', t.id, t.ref, '"'+t.pattern+'"', '|', t.text));
}

// =====================================================
// 통계 요약
// =====================================================
const totalCount = data.length;
const issueVids = new Set();
shortOver50.forEach(v => issueVids.add(v.id));
toneIssues.forEach(v => issueVids.add(v.id));
pUniq.forEach(v => issueVids.add(v.id));
oUniq.forEach(v => issueVids.add(v.id));
interpLenIssues.forEach(v => issueVids.add(v.id));
structureIssues.forEach(v => issueVids.add(v.id));
extDupIssues.forEach(v => issueVids.add(v.id));
appLenIssues.forEach(v => issueVids.add(v.id));
translationIssues.forEach(v => issueVids.add(v.id));

const cleanCount = totalCount - issueVids.size;
const passRate = ((cleanCount / totalCount) * 100).toFixed(1);

console.log('\n==========================================');
console.log('=== 통계 요약 ===');
console.log('==========================================');
console.log('전체 검수 대상:', totalCount, '개');
console.log('verse_short_ko 35자 초과(경고):', shortOver35.length, '건');
console.log('verse_short_ko 50자 초과(위반):', shortOver50.length, '건');
console.log('어투 위반:', toneIssues.length, '건');
console.log('번영신학 위험:', pUniq.length, '건');
console.log('원어 직접 표기:', oUniq.length, '건');
console.log('interpretation 글자수 이탈:', interpLenIssues.length, '건');
console.log('interpretation 구조 미흡(2점↓):', structureIssues.length, '건');
console.log('내부 중복:', internalDupCount, '건');
console.log('기존 v_001~v_319 참조 중복:', extDupIssues.length, '건');
console.log('application 글자수 이탈:', appLenIssues.length, '건');
console.log('개역개정 혼용 의심:', translationIssues.length, '건');
console.log('------------------------------------------');
console.log('문제 구절 수:', issueVids.size, '개');
console.log('클린 구절 수:', cleanCount, '개');
console.log('통과율:', passRate + '%');

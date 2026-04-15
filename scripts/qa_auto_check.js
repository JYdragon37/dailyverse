require('dotenv').config();
/**
 * qa_auto_check.js — 자동 품질 검증 (규칙 기반)
 *
 * 검증 항목:
 *   - 글자수 범위 (verse_full_ko, verse_short_ko, interpretation, application, question)
 *   - 금지 말투 (~이다, ~합니다, 반드시 등)
 *   - 원어 표기 (히브리어·헬라어 단어)
 *
 * 사용법:
 *   node qa_auto_check.js              # active 전체
 *   node qa_auto_check.js --range v_001,v_050
 *   node qa_auto_check.js --force      # 이미 checked 상태도 재검증
 *   node qa_auto_check.js --dry-run    # DB 변경 없이 리포트만
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const args = process.argv.slice(2);
const isDryRun  = args.includes('--dry-run');
const isForce   = args.includes('--force');

const rangeFilter = (() => {
  const idx = args.indexOf('--range');
  if (idx === -1) return null;
  const parts = args[idx + 1].split(',').map(s => s.trim());
  return { start: parseInt(parts[0].replace(/\D/g, '')), end: parseInt(parts[1].replace(/\D/g, '')) };
})();

const LIMITS = {
  verse_full_ko:   { min: 10,  max: 120 },
  verse_short_ko:  { min: 10,  max: 60  },
  interpretation:  { min: 80,  max: 160 },
  application:     { min: 40,  max: 80  },
  question:        { min: 30,  max: 85  },
};

const FORBIDDEN_TONE = ['습니다', '합니다', '입니다', '하십시오', '이다.', '것이다.'];
const FORBIDDEN_ORIGIN = ['히브리어', '헬라어', '아람어', '그리스어'];
const FORBIDDEN_FORCE  = ['반드시', '꼭 ~해야', '해야 한다'];
const ORIGIN_REGEX = /[\u0590-\u05FF\u0370-\u03FF\u1F00-\u1FFF]/;

function autoCheck(data) {
  const issues = [];

  // 1. 필수 필드 존재 확인
  const required = ['verse_full_ko', 'verse_short_ko', 'interpretation', 'application', 'question'];
  required.forEach(f => {
    if (!data[f]) issues.push(`${f}: 필드 없음 또는 빈값`);
  });

  // 2. 글자수 검증
  Object.entries(LIMITS).forEach(([field, { min, max }]) => {
    const text = (data[field] || '').trim();
    if (!text) return;
    const len = text.length;
    if (len < min) issues.push(`${field}: 너무 짧음 (${len}자, 최소 ${min}자)`);
    if (len > max) issues.push(`${field}: 너무 김 (${len}자, 최대 ${max}자)`);
  });

  // 3. 금지 말투 (interpretation, application, question)
  ['interpretation', 'application', 'question'].forEach(field => {
    const text = data[field] || '';
    FORBIDDEN_TONE.forEach(t => {
      if (text.includes(t)) issues.push(`${field}: 금지 말투 ("${t}")`);
    });
    FORBIDDEN_FORCE.forEach(t => {
      if (text.includes(t)) issues.push(`${field}: 강요 표현 ("${t}")`);
    });
    FORBIDDEN_ORIGIN.forEach(t => {
      if (text.includes(t)) issues.push(`${field}: 원어 키워드 ("${t}")`);
    });
    if (ORIGIN_REGEX.test(text)) {
      issues.push(`${field}: 원어 문자 포함 (히브리어/헬라어 스크립트)`);
    }
  });

  // 4. question 신앙 점검 패턴
  const q = data.question || '';
  if (q.includes('기도했나요') || q.includes('말씀을 읽') || q.includes('해야 합니까')) {
    issues.push('question: 신앙 행위 점검 형태');
  }

  return issues;
}

async function main() {
  console.log(`=== qa_auto_check.js | dry-run: ${isDryRun} | force: ${isForce} ===\n`);

  // 전체 active verse_full_ko 로드 → 중복 맵 구성
  const allSnap = await db.collection('verses').where('status', '==', 'active').get();
  const fullKoMap = new Map(); // text → [id, ...]
  allSnap.forEach(doc => {
    const text = (doc.data().verse_full_ko || '').trim();
    if (!text) return;
    if (fullKoMap.has(text)) fullKoMap.get(text).push(doc.id);
    else fullKoMap.set(text, [doc.id]);
  });
  // 중복이 있는 텍스트만 추출
  const duplicateTexts = new Set(
    [...fullKoMap.entries()].filter(([, ids]) => ids.length > 1).map(([text]) => text)
  );
  const dupCount = duplicateTexts.size;
  if (dupCount > 0) console.log(`⚠️  verse_full_ko 중복 감지: ${dupCount}건 (체크 시작 전 정리 권장)\n`);

  const snap = await db.collection('verses').where('status', '==', 'active').orderBy('__name__').get();
  const docs = [];
  snap.forEach(doc => {
    const num = parseInt(doc.id.replace(/\D/g, ''));
    if (rangeFilter && (num < rangeFilter.start || num > rangeFilter.end)) return;
    const d = doc.data();
    // 이미 체크된 것은 force 없으면 스킵
    if (!isForce && d.qa_status && d.qa_status !== 'draft') return;
    docs.push({ id: doc.id, ref: doc.ref, data: d, isDuplicate: duplicateTexts.has((d.verse_full_ko || '').trim()) });
  });

  console.log(`대상: ${docs.length}개\n`);

  let passed = 0, failed = 0;
  const failLog = [];

  for (const { id, ref, data, isDuplicate } of docs) {
    const issues = autoCheck(data);

    // 중복 검증 — verse_full_ko가 다른 active 구절과 동일하면 실패
    if (isDuplicate) {
      const others = fullKoMap.get((data.verse_full_ko || '').trim()).filter(x => x !== id);
      issues.push(`verse_full_ko: 중복 — ${others.join(', ')}과 동일한 텍스트`);
    }
    const pass = issues.length === 0;
    const status = pass ? 'auto_passed' : 'auto_failed';

    if (isDryRun) {
      if (!pass) {
        console.log(`[FAIL] ${id} (${data.reference})`);
        issues.forEach(i => console.log(`  - ${i}`));
      }
    } else {
      await ref.update({
        qa_status:            status,
        qa_issues:            issues,
        qa_checked_at:        admin.firestore.FieldValue.serverTimestamp(),
        qa_guideline_version: 'v9.0',
      });
    }

    if (pass) { passed++; } else {
      failed++;
      failLog.push({ id, ref: data.reference, issues });
    }
  }

  console.log(`\n===== 자동 검증 완료 =====`);
  console.log(`통과: ${passed}개 | 실패: ${failed}개`);
  if (failLog.length) {
    console.log(`\n실패 목록:`);
    failLog.forEach(f => {
      console.log(`  ${f.id} (${f.ref}): ${f.issues.join(' / ').slice(0, 80)}`);
    });
  }
  if (isDryRun) console.log('\n[dry-run: DB 변경 없음]');
  else console.log('\n다음 단계: node qa_ai_check.js');
}

main().catch(console.error).finally(() => process.exit());

require('dotenv').config();
/**
 * qa_report.js — QA 현황 리포트
 *
 * 사용법:
 *   node qa_report.js          # 전체 현황
 *   node qa_report.js --issues # 이슈 있는 항목 상세 출력
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const showIssues = process.argv.includes('--issues');

async function main() {
  const snap = await db.collection('verses').where('status', '==', 'active').orderBy('__name__').get();

  // 중복 감지
  const fullKoMap = new Map();
  snap.forEach(doc => {
    const text = (doc.data().verse_full_ko || '').trim();
    if (!text) return;
    if (fullKoMap.has(text)) fullKoMap.get(text).push(doc.id);
    else fullKoMap.set(text, [doc.id]);
  });
  const dupGroups = [...fullKoMap.values()].filter(ids => ids.length > 1);

  const counts = {
    draft:        0,
    auto_passed:  0,
    auto_failed:  0,
    ai_passed:    0,
    ai_failed:    0,
    approved:     0,
    unknown:      0,
  };
  const issues = [];

  snap.forEach(doc => {
    const d = doc.data();
    const s = d.qa_status || 'draft';
    if (s in counts) counts[s]++;
    else counts.unknown++;

    if ((s === 'auto_failed' || s === 'ai_failed') && d.qa_issues?.length) {
      issues.push({ id: doc.id, ref: d.reference, status: s, issues: d.qa_issues });
    }
  });

  const total = snap.size;
  const approvedPct = Math.round((counts.approved / total) * 100);

  console.log(`\n📊 DailyVerse 콘텐츠 QA 현황 (v9.0)`);
  console.log(`${'─'.repeat(45)}`);
  console.log(`전체 active: ${total}개`);
  console.log(`\n단계별 현황:`);
  console.log(`  ⬜ draft        : ${counts.draft}개`);
  console.log(`  🟡 auto_failed  : ${counts.auto_failed}개`);
  console.log(`  🔵 auto_passed  : ${counts.auto_passed}개`);
  console.log(`  🔴 ai_failed    : ${counts.ai_failed}개`);
  console.log(`  🟢 ai_passed    : ${counts.ai_passed}개`);
  console.log(`  ✅ approved     : ${counts.approved}개  (${approvedPct}%)`);
  if (counts.unknown) console.log(`  ❓ unknown      : ${counts.unknown}개`);

  const pending = counts.auto_failed + counts.ai_failed;
  const ready   = counts.ai_passed;

  console.log(`\n📌 액션 필요:`);
  if (counts.draft > 0)     console.log(`  → qa_auto_check.js 실행 필요: ${counts.draft}개`);
  if (counts.auto_passed > 0) console.log(`  → qa_ai_check.js 실행 필요: ${counts.auto_passed}개`);
  if (pending > 0)          console.log(`  → 수정 후 재검증 필요: ${pending}개`);
  if (ready > 0)            console.log(`  → qa_approve.js 실행 가능: ${ready}개`);
  if (pending === 0 && counts.draft === 0 && counts.auto_passed === 0)
    console.log(`  → 모든 콘텐츠 검증 완료 ✅`);

  // 중복 리포트
  if (dupGroups.length > 0) {
    console.log(`\n🔴 verse_full_ko 중복: ${dupGroups.length}건 → qa_auto_check.js 실행 시 auto_failed 처리됨`);
    dupGroups.forEach(ids => console.log(`   ${ids.join(' / ')}`));
  } else {
    console.log(`\n✅ verse_full_ko 중복 없음`);
  }

  if (showIssues && issues.length > 0) {
    console.log(`\n⚠️  이슈 목록 (${issues.length}개):`);
    issues.forEach(({ id, ref, status, issues: issueList }) => {
      console.log(`\n  [${status}] ${id} (${ref})`);
      issueList.forEach(i => console.log(`    - ${i}`));
    });
  }

  console.log();
}

main().catch(console.error).finally(() => process.exit());

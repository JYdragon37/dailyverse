/**
 * fix_content_checker_results.js
 * content-checker 검수 결과 적용 스크립트
 *
 * 수정 항목:
 *  - Critical 1: v_290 status → inactive (번영신학 위험)
 *  - Critical 2: 개역한글 번역 오류 수정 (v_226, v_233, v_277)
 *  - High 1: verse_short_ko 길이 초과 축약 (v_296, v_298, v_299)
 *  - High 2: 중복 구절 inactive 처리 (v_222, v_223, v_230, v_254, v_292, v_286)
 *  - High 3 + Medium: application/interpretation "기억해." → "기억해봐." 수정
 */

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const { google } = require('googleapis');
const key = require('./serviceAccountKey.json');

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const VERSES_TAB = 'VERSES';

// 컬럼 인덱스 (0-based, A=0)
const COL = {
  verse_id:        0,  // A
  verse_short_ko:  1,  // B
  verse_full_ko:   2,  // C
  reference:       3,  // D
  interpretation:  12, // M
  application:     13, // N
  status:          15, // P
};

async function main() {
  const auth = new google.auth.GoogleAuth({
    credentials: key,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const client = await auth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });

  // --- 1. VERSES 탭 전체 읽기 ---
  console.log('VERSES 탭 전체 데이터 로드 중...');
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SPREADSHEET_ID,
    range: `${VERSES_TAB}!A:Q`,
  });
  const rows = res.data.values || [];
  console.log(`총 ${rows.length}행 로드 완료 (헤더 포함)\n`);

  // verse_id → row index 매핑 (1-based sheet row)
  const verseRowMap = {};
  rows.forEach((row, i) => {
    const vid = (row[COL.verse_id] || '').trim();
    if (vid) verseRowMap[vid] = i + 1; // 1-based
  });

  // 업데이트 배치 수집
  const updates = [];
  const results = [];

  // 헬퍼: 특정 셀 업데이트 예약
  function scheduleUpdate(verseId, colLetter, newValue, label, before, after) {
    const rowNum = verseRowMap[verseId];
    if (!rowNum) {
      console.warn(`[WARN] ${verseId} 행을 찾을 수 없음`);
      return;
    }
    updates.push({
      range: `${VERSES_TAB}!${colLetter}${rowNum}`,
      values: [[newValue]],
    });
    results.push({ verseId, field: label, before, after, rowNum });
  }

  // 헬퍼: 행 데이터 가져오기
  function getRow(verseId) {
    const rowNum = verseRowMap[verseId];
    if (!rowNum) return null;
    return rows[rowNum - 1];
  }

  // ═══════════════════════════════════════════════
  // Critical 1: v_290 status → inactive
  // ═══════════════════════════════════════════════
  console.log('--- Critical 1: 번영신학 위험 inactive 처리 ---');
  {
    const vid = 'v_290';
    const row = getRow(vid);
    if (row) {
      const before = row[COL.status] || '';
      scheduleUpdate(vid, 'P', 'inactive', 'status', before, 'inactive');
      console.log(`  ${vid}: status "${before}" → "inactive"`);
    }
  }

  // ═══════════════════════════════════════════════
  // Critical 2: 개역한글 번역 오류 수정
  // ═══════════════════════════════════════════════
  console.log('\n--- Critical 2: 개역한글 번역 오류 수정 ---');

  // v_226 (요한복음 14:27): "평안을" → "평강을"
  {
    const vid = 'v_226';
    const row = getRow(vid);
    if (row) {
      const fullKo = row[COL.verse_full_ko] || '';
      const shortKo = row[COL.verse_short_ko] || '';

      const newFullKo = fullKo.replace(/평안을/g, '평강을').replace(/평안이/g, '평강이').replace(/평안을 너희에게/g, '평강을 너희에게');
      const newShortKo = shortKo.replace(/평안/g, '평강');

      if (newFullKo !== fullKo) {
        scheduleUpdate(vid, 'C', newFullKo, 'verse_full_ko', fullKo.slice(0, 40), newFullKo.slice(0, 40));
        console.log(`  ${vid} verse_full_ko: "평안" → "평강" 수정`);
      } else {
        console.log(`  ${vid} verse_full_ko: "평안" 없음, 현재값 확인 필요`);
        console.log(`    현재: ${fullKo.slice(0, 60)}`);
      }

      if (newShortKo !== shortKo) {
        scheduleUpdate(vid, 'B', newShortKo, 'verse_short_ko', shortKo, newShortKo);
        console.log(`  ${vid} verse_short_ko: "평안" → "평강" 수정`);
      } else {
        console.log(`  ${vid} verse_short_ko: 이미 "평강" 포함 또는 없음 — 현재값: ${shortKo}`);
      }
    }
  }

  // v_233 (요한복음 3:16): "그를 믿는 자마다 멸망하지 않고" → "저를 믿는 자마다 멸망치 않고"
  {
    const vid = 'v_233';
    const row = getRow(vid);
    if (row) {
      const fullKo = row[COL.verse_full_ko] || '';
      const shortKo = row[COL.verse_short_ko] || '';

      let newFullKo = fullKo
        .replace(/그를 믿는 자마다 멸망하지 않고/g, '저를 믿는 자마다 멸망치 않고')
        .replace(/그를 믿는 자마다/g, '저를 믿는 자마다')
        .replace(/멸망하지 않고/g, '멸망치 않고');

      let newShortKo = shortKo
        .replace(/그를 믿는 자마다 멸망하지 않고/g, '저를 믿는 자마다 멸망치 않고')
        .replace(/그를 믿는 자마다/g, '저를 믿는 자마다')
        .replace(/멸망하지 않고/g, '멸망치 않고');

      if (newFullKo !== fullKo) {
        scheduleUpdate(vid, 'C', newFullKo, 'verse_full_ko', fullKo.slice(0, 40), newFullKo.slice(0, 40));
        console.log(`  ${vid} verse_full_ko: 개역한글 원문으로 수정`);
      } else {
        console.log(`  ${vid} verse_full_ko: 이미 수정됨 또는 다른 표현 — 현재: ${fullKo.slice(0, 60)}`);
      }

      if (newShortKo !== shortKo) {
        scheduleUpdate(vid, 'B', newShortKo, 'verse_short_ko', shortKo, newShortKo);
        console.log(`  ${vid} verse_short_ko: 개역한글 원문으로 수정`);
      } else {
        console.log(`  ${vid} verse_short_ko: 변경 없음 — 현재: ${shortKo}`);
      }
    }
  }

  // v_277 (예레미야 29:13): "온 마음으로 나를 찾으면" → "전심으로 나를 찾으면"
  {
    const vid = 'v_277';
    const row = getRow(vid);
    if (row) {
      const fullKo = row[COL.verse_full_ko] || '';
      const shortKo = row[COL.verse_short_ko] || '';

      const newFullKo = fullKo.replace(/온 마음으로 나를 찾으면/g, '전심으로 나를 찾으면');
      const newShortKo = shortKo.replace(/온 마음으로/g, '전심으로');

      if (newFullKo !== fullKo) {
        scheduleUpdate(vid, 'C', newFullKo, 'verse_full_ko', fullKo.slice(0, 40), newFullKo.slice(0, 40));
        console.log(`  ${vid} verse_full_ko: "온 마음으로" → "전심으로" 수정`);
      } else {
        console.log(`  ${vid} verse_full_ko: 이미 "전심으로" 사용 중 또는 다른 표현 — 현재: ${fullKo.slice(0, 60)}`);
      }

      if (newShortKo !== shortKo) {
        scheduleUpdate(vid, 'B', newShortKo, 'verse_short_ko', shortKo, newShortKo);
        console.log(`  ${vid} verse_short_ko: "온 마음으로" → "전심으로" 수정`);
      }
    }
  }

  // ═══════════════════════════════════════════════
  // High 1: verse_short_ko 길이 초과 축약
  // ═══════════════════════════════════════════════
  console.log('\n--- High 1: verse_short_ko 길이 초과 축약 ---');

  const shortKoFixes = {
    'v_296': '오직 겸손한 마음으로 각각 자기보다 남을 낫게 여기라.',
    'v_298': '능력과 사랑과 근신하는 마음을 주셨느니라.',
    'v_299': '주야로 묵상하여 기록한 대로 다 지켜 행하라.',
  };

  for (const [vid, newShort] of Object.entries(shortKoFixes)) {
    const row = getRow(vid);
    if (row) {
      const before = row[COL.verse_short_ko] || '';
      console.log(`  ${vid}: ${before.length}자 → ${newShort.length}자`);
      console.log(`    전: ${before}`);
      console.log(`    후: ${newShort}`);
      scheduleUpdate(vid, 'B', newShort, 'verse_short_ko', before, newShort);
    }
  }

  // ═══════════════════════════════════════════════
  // High 2: 중복 구절 inactive 처리
  // ═══════════════════════════════════════════════
  console.log('\n--- High 2: 중복 구절 inactive 처리 ---');

  const inactiveTargets = ['v_222', 'v_223', 'v_230', 'v_254', 'v_292', 'v_286'];
  for (const vid of inactiveTargets) {
    const row = getRow(vid);
    if (row) {
      const before = row[COL.status] || '';
      const ref = row[COL.reference] || '';
      scheduleUpdate(vid, 'P', 'inactive', 'status', before, 'inactive');
      console.log(`  ${vid} (${ref}): status "${before}" → "inactive"`);
    }
  }

  // ═══════════════════════════════════════════════
  // High 3: application "기억해." → "기억해봐."
  // ═══════════════════════════════════════════════
  console.log('\n--- High 3: application "기억해." → "기억해봐." ---');

  const applicationFixes = ['v_283', 'v_285', 'v_291', 'v_293', 'v_294', 'v_298'];
  for (const vid of applicationFixes) {
    const row = getRow(vid);
    if (row) {
      const before = row[COL.application] || '';
      if (before.includes('기억해.')) {
        const after = before.replace(/기억해\./g, '기억해봐.');
        scheduleUpdate(vid, 'N', after, 'application', before, after);
        console.log(`  ${vid}: application "기억해." → "기억해봐." 수정`);
        console.log(`    전: ${before.slice(0, 60)}`);
        console.log(`    후: ${after.slice(0, 60)}`);
      } else {
        console.log(`  ${vid}: application에 "기억해." 없음 — 현재: ${before.slice(0, 60)}`);
      }
    }
  }

  // ═══════════════════════════════════════════════
  // Medium: interpretation "기억해." → "기억해봐."
  // ═══════════════════════════════════════════════
  console.log('\n--- Medium: interpretation "기억해." → "기억해봐." ---');

  const interpFixes = ['v_221', 'v_228', 'v_233', 'v_234', 'v_237', 'v_284'];
  for (const vid of interpFixes) {
    const row = getRow(vid);
    if (row) {
      const before = row[COL.interpretation] || '';
      if (before.includes('기억해.')) {
        const after = before.replace(/기억해\./g, '기억해봐.');
        scheduleUpdate(vid, 'M', after, 'interpretation', before, after);
        console.log(`  ${vid}: interpretation "기억해." → "기억해봐." 수정`);
        console.log(`    전: ${before.slice(0, 60)}`);
        console.log(`    후: ${after.slice(0, 60)}`);
      } else {
        console.log(`  ${vid}: interpretation에 "기억해." 없음 — 현재: ${before.slice(0, 60)}`);
      }
    }
  }

  // ═══════════════════════════════════════════════
  // 배치 업데이트 실행
  // ═══════════════════════════════════════════════
  console.log(`\n총 ${updates.length}건 업데이트 예정`);

  if (updates.length === 0) {
    console.log('업데이트할 항목 없음');
    return;
  }

  console.log('Google Sheets 배치 업데이트 실행 중...');
  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SPREADSHEET_ID,
    requestBody: {
      valueInputOption: 'RAW',
      data: updates,
    },
  });

  console.log('\n업데이트 완료!\n');

  // ═══════════════════════════════════════════════
  // 결과 출력
  // ═══════════════════════════════════════════════
  console.log('═'.repeat(80));
  console.log('수정 결과 요약');
  console.log('═'.repeat(80));
  console.log(`| ${'verse_id'.padEnd(8)} | ${'필드'.padEnd(16)} | ${'수정 전 (핵심)'.padEnd(30)} | ${'수정 후 (핵심)'.padEnd(30)} |`);
  console.log(`| ${'-'.repeat(8)} | ${'-'.repeat(16)} | ${'-'.repeat(30)} | ${'-'.repeat(30)} |`);
  for (const r of results) {
    const before = (r.before || '').slice(0, 28).padEnd(30);
    const after  = (r.after  || '').slice(0, 28).padEnd(30);
    console.log(`| ${r.verseId.padEnd(8)} | ${r.field.padEnd(16)} | ${before} | ${after} |`);
  }
  console.log('\n총 ' + results.length + '건 수정 완료.');
  console.log('Firestore 동기화 필요 시: node scripts/sync_sheets_to_firestore.js');
}

main().catch(err => {
  console.error('오류 발생:', err.message);
  process.exit(1);
});

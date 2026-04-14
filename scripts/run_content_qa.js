/**
 * run_content_qa.js
 * DailyVerse 콘텐츠 QA 마스터 오케스트레이션
 *
 * Usage:
 *   node scripts/run_content_qa.js              # 점검만 (기계적 체크)
 *   node scripts/run_content_qa.js --fix        # 점검 + 자동 수정 (기계적 가능한 것)
 *   node scripts/run_content_qa.js --sync       # 점검 + Firestore 동기화
 *   node scripts/run_content_qa.js --full       # 전체 (점검 + 수정 + 동기화)
 *   node scripts/run_content_qa.js --tab ALARM_VERSES  # 다른 탭
 *
 * 기계적 자동 체크 항목:
 *   ✅ 글자수 (interpretation ≤200, application ≤100)
 *   ✅ 원어 직접 표기 (known_original_language_words 목록 기반)
 *   ✅ 어투 위반 (forbidden_tone_patterns 기반)
 *   ✅ 중복 ID
 *   ✅ 빈값
 *
 * AI 에이전트 필요 항목 (결과에 플래그만):
 *   ⚠️  Zone 맥락 정합성 → content-checker 에이전트 사용
 *   ⚠️  interpretation 구조 완성도 → content-checker 에이전트 사용
 */

const { fetchVerses } = require('./fetch_verses');
const { logResults, markFixed } = require('./qa_logger');
const rules = require('./content-rules.json');

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

const key = require('./serviceAccountKey.json');
const sheetsAuth = new google.auth.GoogleAuth({
  credentials: key,
  scopes: ['https://www.googleapis.com/auth/spreadsheets'],
});

// ─────────────────────────────────────────────
// 유틸
// ─────────────────────────────────────────────

function generateRunId() {
  const d = new Date();
  const date = d.toISOString().slice(0, 10);
  const time = d.toISOString().slice(11, 16).replace(':', '');
  return `QA-${date}-${time}`;
}

function charCount(str) {
  return (str || '').length;
}

// ─────────────────────────────────────────────
// 점검 함수들
// ─────────────────────────────────────────────

function checkCharLimits(verses) {
  const issues = [];
  const limits = rules.char_limits;

  verses.forEach(v => {
    const checks = [
      { field: 'interpretation', value: v.interpretation },
      { field: 'application',    value: v.application },
    ];

    checks.forEach(({ field, value }) => {
      const limit = limits[field];
      if (!limit) return;
      const len = charCount(value);

      if (!value || len === 0) {
        issues.push({
          verse_id: v.verse_id, reference: v.reference,
          check_type: 'char_limit', status: 'fail', severity: 'critical',
          issue: `${field} 빈값`, fixed: 'N',
        });
      } else if (len > limit.max) {
        issues.push({
          verse_id: v.verse_id, reference: v.reference,
          check_type: 'char_limit', status: 'fail', severity: 'high',
          issue: `${field} ${len}자 > ${limit.max}자`, fixed: 'N',
        });
      }
    });
  });

  return issues;
}

function checkOriginalLanguage(verses) {
  const issues = [];
  const words = rules.known_original_language_words;
  const patterns = rules.forbidden_original_language_patterns;

  verses.forEach(v => {
    const text = v.interpretation + ' ' + v.application;

    // known words 검색
    words.forEach(word => {
      if (text.includes(word)) {
        issues.push({
          verse_id: v.verse_id, reference: v.reference,
          check_type: 'original_language', status: 'fail', severity: 'high',
          issue: `원어 단어 직접 표기: "${word}"`, fixed: 'N',
          notes: `interpretation 또는 application에 포함`,
        });
      }
    });

    // 추가: 따옴표 패턴 중 외래어(로마자 음역)로 보이는 것만 감지
    // 조건: 한글이지만 known_words 목록 미등록 + 3음절 이상 + 발음이 외래어스러운 패턴
    // (예: ~오오, ~아아, ~이스, ~노스 등 전형적 헬라어 어미)
    const greekPattern = /"([가-힣]{3,12}(?:오오|이스|아스|노스|이아|오스|에오|시스))"는/g;
    let match;
    while ((match = greekPattern.exec(text)) !== null) {
      const word = match[1];
      if (!words.includes(word) && !issues.find(i => i.verse_id === v.verse_id && i.check_type === 'original_language')) {
        issues.push({
          verse_id: v.verse_id, reference: v.reference,
          check_type: 'original_language', status: 'fail', severity: 'high',
          issue: `미등록 원어 음역 의심: "${word}" → known list에 추가 후 재확인 필요`, fixed: 'N',
        });
      }
    }
  });

  return issues;
}

function checkTone(verses) {
  const issues = [];
  const patterns = rules.forbidden_tone_patterns;

  verses.forEach(v => {
    const app = v.application || '';
    patterns.forEach(p => {
      if (app.includes(p.pattern)) {
        issues.push({
          verse_id: v.verse_id, reference: v.reference,
          check_type: 'tone', status: 'fail', severity: 'high',
          issue: `어투 위반: "${p.pattern}" (${p.reason})`,
          fixed: 'N',
          notes: `제안: ${p.suggest}`,
        });
      }
    });
  });

  return issues;
}

function checkDuplicates(verses) {
  const issues = [];
  const seen = new Map();

  verses.forEach(v => {
    if (seen.has(v.verse_id)) {
      issues.push({
        verse_id: v.verse_id, reference: v.reference,
        check_type: 'duplicate_id', status: 'fail', severity: 'critical',
        issue: `중복 verse_id (row ${seen.get(v.verse_id)} & ${v._row})`,
        fixed: 'N',
      });
    } else {
      seen.set(v.verse_id, v._row);
    }
  });

  return issues;
}

function checkEmptyFields(verses) {
  const issues = [];
  const required = ['verse_short_ko', 'verse_full_ko', 'reference', 'interpretation', 'application'];

  verses.forEach(v => {
    required.forEach(field => {
      if (!v[field] || v[field].trim() === '') {
        issues.push({
          verse_id: v.verse_id, reference: v.reference || '(없음)',
          check_type: 'empty_field', status: 'fail', severity: 'critical',
          issue: `필수 필드 빈값: ${field}`, fixed: 'N',
        });
      }
    });
  });

  return issues;
}

// ─────────────────────────────────────────────
// 자동 수정 (기계적으로 가능한 것)
// ─────────────────────────────────────────────

async function autoFix(verses, issues) {
  const fixable = issues.filter(i => i.check_type === 'tone' && i.status === 'fail');
  if (fixable.length === 0) return [];

  const client = await sheetsAuth.getClient();
  const sheets = google.sheets({ version: 'v4', auth: client });
  const spreadsheetId = rules.spreadsheet.id;

  const fixed = [];

  for (const issue of fixable) {
    const verse = verses.find(v => v.verse_id === issue.verse_id);
    if (!verse) continue;

    let newApp = verse.application;
    const patterns = rules.forbidden_tone_patterns;

    // 패턴별 자동 교체 (간단한 것만)
    const simpleReplacements = {
      '기억해.':    '생각해봐.',
      '반드시 있어.': '분명 있을 거야.',
    };

    let changed = false;
    for (const [from, to] of Object.entries(simpleReplacements)) {
      if (newApp.includes(from)) {
        newApp = newApp.replace(from, to);
        changed = true;
      }
    }

    if (changed) {
      await sheets.spreadsheets.values.update({
        spreadsheetId,
        range: `${rules.spreadsheet.tabs.verses}!N${verse._row}`,
        valueInputOption: 'RAW',
        requestBody: { values: [[newApp]] },
      });
      issue.fixed = 'Y';
      fixed.push(verse.verse_id);
      console.log(`  수정: ${verse.verse_id} (${verse.reference})`);
    }
  }

  return fixed;
}

// ─────────────────────────────────────────────
// 메인
// ─────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const doFix  = args.includes('--fix')  || args.includes('--full');
  const doSync = args.includes('--sync') || args.includes('--full');
  const tabIdx = args.indexOf('--tab');
  const tab    = tabIdx >= 0 ? args[tabIdx + 1] : rules.spreadsheet.tabs.verses;

  const runId = generateRunId();
  console.log(`\n🔍 DailyVerse 콘텐츠 QA 시작`);
  console.log(`   run_id : ${runId}`);
  console.log(`   탭     : ${tab}`);
  console.log(`   모드   : ${doFix ? '점검+수정' : '점검만'}${doSync ? '+동기화' : ''}`);
  console.log('─'.repeat(50));

  // Step 1: 데이터 수집
  console.log('\n[1/4] 데이터 수집 중...');
  const verses = await fetchVerses({ tab, outPath: '/tmp/verses_check.json' });

  // Step 2: 기계적 점검
  console.log('\n[2/4] 기계적 점검 중...');
  const allIssues = [
    ...checkEmptyFields(verses),
    ...checkDuplicates(verses),
    ...checkCharLimits(verses),
    ...checkOriginalLanguage(verses),
    ...checkTone(verses),
  ];

  // 결과 출력
  const critical = allIssues.filter(i => i.severity === 'critical');
  const high     = allIssues.filter(i => i.severity === 'high');
  const other    = allIssues.filter(i => !['critical','high'].includes(i.severity));

  console.log(`\n📊 점검 결과 (총 ${allIssues.length}건)`);
  console.log(`   🔴 Critical : ${critical.length}건`);
  console.log(`   🟠 High     : ${high.length}건`);
  console.log(`   🟡 기타     : ${other.length}건`);

  if (allIssues.length > 0) {
    console.log('\n위반 목록:');
    allIssues.forEach(i =>
      console.log(`  [${i.severity.toUpperCase()}] ${i.verse_id} (${i.reference}) — ${i.issue}`)
    );
  } else {
    console.log('✅ 기계적 점검 통과 — 위반 없음');
  }

  // Step 3: 자동 수정
  let fixedIds = [];
  if (doFix && allIssues.length > 0) {
    console.log('\n[3/4] 자동 수정 중...');
    fixedIds = await autoFix(verses, allIssues);
    console.log(`  수정 완료: ${fixedIds.length}건`);
  } else {
    console.log('\n[3/4] 자동 수정 스킵');
  }

  // Step 4: QA_LOG 기록
  console.log('\n[4/4] QA_LOG 기록 중...');
  if (allIssues.length > 0) {
    await logResults(runId, allIssues);
    if (fixedIds.length > 0) {
      await markFixed(runId, fixedIds, 'auto-script');
    }
  } else {
    await logResults(runId, [{
      verse_id: 'ALL', reference: 'ALL',
      check_type: 'summary', status: 'pass', severity: 'info',
      issue: `전체 ${verses.length}개 구절 기계적 점검 통과`, fixed: 'N',
    }]);
  }

  // Firestore 동기화
  if (doSync) {
    console.log('\n🔄 Firestore 동기화 중...');
    const { execSync } = require('child_process');
    execSync('node sync_sheets_to_firestore.js', { stdio: 'inherit', cwd: __dirname });
  }

  console.log(`\n✅ QA 완료 (run_id: ${runId})`);
  console.log(`\n💡 AI 에이전트 점검이 필요한 항목:`);
  console.log(`   - Zone 맥락 정합성: content-checker 에이전트 사용`);
  console.log(`   - interpretation 구조: content-checker 에이전트 사용`);
  console.log(`   Claude Code에서: "콘텐츠 점검해줘" 또는 "@content-checker 실행"`);
}

main().catch(err => {
  console.error('오류:', err.message);
  process.exit(1);
});

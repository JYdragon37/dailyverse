/**
 * fill_contemplation_rest.js
 * 40개 missing contemplation 필드 생성 — Sheets + Firestore REST API (gRPC 우회)
 *
 * 사용법:
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 node fill_contemplation_rest.js
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 node fill_contemplation_rest.js --dry-run
 */
require('dotenv').config();
const { google } = require('googleapis');
const Anthropic = require('@anthropic-ai/sdk');
const https = require('https');
const sa = require('./serviceAccountKey.json');

const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const PROJECT  = sa.project_id;
const IS_DRY   = process.argv.includes('--dry-run');
const agent    = new https.Agent({ rejectUnauthorized: false });

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// ── 헬퍼: Firestore REST 업데이트 ─────────────────────────────
async function firestoreUpdate(token, verseId, fields) {
  const { default: fetch } = await import('node-fetch');
  // updateMask는 필드마다 별도 파라미터로 전달해야 함
  const maskParams = Object.keys(fields).map(k => `updateMask.fieldPaths=${k}`).join('&');
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/verses/${verseId}?${maskParams}`;
  const body = {
    fields: Object.fromEntries(
      Object.entries(fields).map(([k, v]) => [k, { stringValue: v }])
    )
  };
  const res = await fetch(url, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    agent
  });
  if (!res.ok) throw new Error(`Firestore PATCH failed: ${res.status} ${await res.text()}`);
}

// ── 헬퍼: Sheets 셀 업데이트 ──────────────────────────────────
async function sheetsUpdate(sheetsClient, rowNum, cInterpVal, cApplVal) {
  // 헤더에서 contemplation_interpretation(col 25=Y), contemplation_appliance(col 26=Z) 확인
  await sheetsClient.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: {
      valueInputOption: 'RAW',
      data: [
        { range: `VERSES!Y${rowNum}`, values: [[cInterpVal]] },
        { range: `VERSES!Z${rowNum}`, values: [[cApplVal]] }
      ]
    }
  });
}

// ── 프롬프트 ──────────────────────────────────────────────────
function buildPrompt(verse) {
  const modeKo = {
    deep_dark:   '새벽 00-03시 (극야, 잠 못 드는 고요한 시간)',
    first_light: '새벽 03-06시 (여명, 하루를 준비하는 고요한 시간)',
    rise_ignite: '아침 06-09시 (활기차게 하루를 시작하는 시간)',
    peak_mode:   '오전 09-12시 (집중력이 높은 피크 시간)',
    recharge:    '오후 12-15시 (잠깐 충전이 필요한 시간)',
    second_wind: '오후 15-18시 (다시 힘을 내야 하는 시간)',
    golden_hour: '저녁 18-21시 (하루를 돌아보는 황금시간)',
    wind_down:   '밤 21-24시 (하루를 마무리하는 시간)',
    all:         '전 시간대 공통'
  };
  const modeDesc = (verse.mode || '').split(',').map(m => modeKo[m.trim()] || m.trim()).join(', ');

  return `너는 DailyVerse 앱의 묵상 콘텐츠 작성자야. 아래 성경 구절에 대해 두 가지 텍스트를 작성해줘.

## 구절 정보
- reference: ${verse.ref}
- verse_short_ko: ${verse.shortKo}
- verse_full_ko: ${verse.fullKo}
- 시간대/모드: ${modeDesc}
- 기존 interpretation(짧은 버전): ${verse.interp}
- 기존 application(짧은 버전): ${verse.appl}

## 작성 규격

### contemplation_interpretation (깊은 해석)
- 분량: 80~150자 (공백 포함)
- 구조: ① 구절 배경 1문장 → ② 핵심 의미 1~2문장 → ③ 묵상 연결 1문장
- 말투: ~야, ~이야, ~거야 (친근한 반말)
- 금지: 원어 히브리어/헬라어 표기, 설교조, "~해야 한다", "~하십시오"
- 시간대 반영: 위의 시간대에 맞는 분위기로

### contemplation_appliance (깊은 일상 적용)
- 분량: 40~80자 (공백 포함)
- 구조: 오늘 바로 할 수 있는 구체적 행동/태도 1가지
- 말투: ~해봐, ~기억해, ~생각해봐 (친근한 반말)
- 금지: ~해야 한다, 설교조, 추상적 표현
- 시간대 반영: 아침이면 시작, 저녁이면 마무리 관련 행동

## 출력 형식 (JSON만, 설명 없이)
{
  "contemplation_interpretation": "...",
  "contemplation_appliance": "..."
}`;
}

// ── 메인 ──────────────────────────────────────────────────────
(async () => {
  console.log('📖 Sheets 인증 중...');
  const auth = new google.auth.GoogleAuth({
    credentials: sa,
    scopes: ['https://www.googleapis.com/auth/spreadsheets']
  });
  const sheetsClient = google.sheets({ version: 'v4', auth: await auth.getClient() });

  // 헤더 확인 (contemplation 컬럼 위치)
  const headerRes = await sheetsClient.spreadsheets.values.get({
    spreadsheetId: SHEET_ID, range: 'VERSES!A1:AZ1'
  });
  const headers = headerRes.data.values[0];
  const cInterpColIdx = headers.indexOf('contemplation_interpretation'); // 0-based
  const cApplColIdx   = headers.indexOf('contemplation_appliance');
  const colLetter = i => String.fromCharCode(65 + i);
  console.log(`contemplation_interpretation 컬럼: ${colLetter(cInterpColIdx)} (${cInterpColIdx})`);
  console.log(`contemplation_appliance 컬럼:      ${colLetter(cApplColIdx)} (${cApplColIdx})`);

  // Firestore 토큰
  const fsAuth = new google.auth.GoogleAuth({ credentials: sa, scopes: ['https://www.googleapis.com/auth/datastore'] });
  const fsToken = (await (await fsAuth.getClient()).getAccessToken()).token;

  // 누락 구절 로드
  const missing = require('/tmp/missing_verses.json');
  console.log(`\n🎯 생성 대상: ${missing.length}개${IS_DRY ? ' (dry-run)' : ''}\n`);

  let ok = 0, fail = 0;

  for (const verse of missing) {
    process.stdout.write(`[${verse.id}] ${verse.ref} ... `);

    try {
      const msg = await anthropic.messages.create({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 400,
        messages: [{ role: 'user', content: buildPrompt(verse) }]
      });

      const raw = msg.content[0].text.trim();
      // JSON 파싱
      const jsonMatch = raw.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('JSON 파싱 실패: ' + raw.substring(0, 80));
      const result = JSON.parse(jsonMatch[0]);

      const ci = (result.contemplation_interpretation || '').trim();
      const ca = (result.contemplation_appliance || '').trim();

      if (!ci || !ca) throw new Error('빈 값 반환');

      console.log(`✅ (${ci.length}자 / ${ca.length}자)`);
      if (IS_DRY) {
        console.log(`  interpretation: ${ci}`);
        console.log(`  appliance:      ${ca}`);
      } else {
        // Sheets 업데이트
        const cInterpRange = `VERSES!${colLetter(cInterpColIdx)}${verse.row}`;
        const cApplRange   = `VERSES!${colLetter(cApplColIdx)}${verse.row}`;
        await sheetsClient.spreadsheets.values.batchUpdate({
          spreadsheetId: SHEET_ID,
          requestBody: {
            valueInputOption: 'RAW',
            data: [
              { range: cInterpRange, values: [[ci]] },
              { range: cApplRange,   values: [[ca]] }
            ]
          }
        });

        // Firestore REST 업데이트
        await firestoreUpdate(fsToken, verse.id, {
          contemplation_interpretation: ci,
          contemplation_appliance: ca
        });
      }
      ok++;
    } catch (e) {
      console.log(`❌ ${e.message}`);
      fail++;
    }

    // Rate limit 방지
    await new Promise(r => setTimeout(r, 800));
  }

  console.log(`\n═══════════════════════════════`);
  console.log(`✅ 성공: ${ok}개  ❌ 실패: ${fail}개`);
  console.log(IS_DRY ? '(dry-run — 실제 반영 안 됨)' : '📤 Sheets + Firestore 업데이트 완료');
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });

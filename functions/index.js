/**
 * morning manna — Firebase Cloud Functions
 *
 * [1] previewDailyVerses  (01:00 KST)
 *     D / D+1 / D+2 말씀을 미리 선정하고 Firestore verse_schedule/{date}에 기록.
 *     → 관리자가 Google Sheets VERSE_PREVIEW 탭에서 확인·수정 가능.
 *
 * [2] selectDailyVerse    (04:00 KST)
 *     오늘의 말씀을 확정해 app_config/today_verse에 기록.
 *     verse_schedule/{today}가 있으면 그 verse를 사용(관리자 선정 우선).
 *     없으면 알고리즘으로 자동 선택.
 *
 * [3] getVerseSchedule    (HTTP GET)
 *     D/D+1/D+2 스케줄 데이터를 JSON으로 반환.
 *     Google Sheets Apps Script가 이 엔드포인트를 호출해 시트를 업데이트.
 *
 * [4] applyVerseOverrides (HTTP POST)
 *     Google Sheets "적용하기" 버튼이 호출.
 *     관리자가 선택한 override를 verse_schedule에 저장.
 */

const { onSchedule }  = require('firebase-functions/v2/scheduler');
const { onRequest }   = require('firebase-functions/v2/https');
const { logger }      = require('firebase-functions');
const admin           = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ─── 공통 헬퍼 ──────────────────────────────────────────────────────────────

/**
 * KST 기준 날짜 오프셋 계산 (0=오늘, 1=내일, 2=모레)
 * @returns { year, month, day, dateStr, dayInt, kstDate }
 */
function kstDateOffset(offsetDays = 0) {
  const now    = new Date();
  const kst    = new Date(now.getTime() + 9 * 60 * 60 * 1000 + offsetDays * 86400000);
  const year   = kst.getUTCFullYear();
  const month  = kst.getUTCMonth() + 1;
  const day    = kst.getUTCDate();
  const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  const dayInt  = year * 10000 + month * 100 + day;
  return { year, month, day, dateStr, dayInt, kstDate: kst };
}

/**
 * 주어진 날짜 dayInt 기준으로 eligible 구절 풀에서 말씀 선택.
 * excludeIds: 이미 D/D+1에서 선택된 ID (연속 중복 방지)
 */
function pickVerse(allVerses, dayInt, excludeIds = []) {
  const now = new Date();

  // cooldown 통과 + excludeIds 제외
  let pool = allVerses.filter(v => {
    if (excludeIds.includes(v.id)) return false;
    if (!v.last_shown) return true;
    const lastShown = v.last_shown.toDate ? v.last_shown.toDate() : new Date(v.last_shown);
    const daysSince = (now - lastShown) / (1000 * 60 * 60 * 24);
    const cooldown  = typeof v.cooldown_days === 'number' ? v.cooldown_days : 7;
    return daysSince >= cooldown;
  });

  // pool이 비면 excludeIds만 제외 (cooldown 완화)
  if (pool.length === 0) pool = allVerses.filter(v => !excludeIds.includes(v.id));
  // 그래도 비면 전체 사용
  if (pool.length === 0) pool = allVerses;

  const sorted = [...pool].sort((a, b) => a.id.localeCompare(b.id));
  return sorted[dayInt % sorted.length];
}

/**
 * 대안 후보 3개 선택 (autoSelected 제외, 각각 dayInt 오프셋으로 분산)
 */
function pickAlternatives(allVerses, dayInt, autoSelectedId, excludeIds = []) {
  const now = new Date();
  const candidates = allVerses.filter(v => {
    if (v.id === autoSelectedId) return false;
    if (excludeIds.includes(v.id)) return false;
    if (!v.last_shown) return true;
    const lastShown = v.last_shown.toDate ? v.last_shown.toDate() : new Date(v.last_shown);
    const daysSince = (now - lastShown) / (1000 * 60 * 60 * 24);
    const cooldown  = typeof v.cooldown_days === 'number' ? v.cooldown_days : 7;
    return daysSince >= cooldown;
  });

  if (candidates.length === 0) return [];
  const sorted = [...candidates].sort((a, b) => a.id.localeCompare(b.id));
  const step   = Math.max(1, Math.floor(sorted.length / 4));
  const alts   = [];
  for (let i = 1; i <= 3; i++) {
    const idx = (dayInt + i * step) % sorted.length;
    const c   = sorted[idx];
    if (c && !alts.some(a => a.id === c.id)) alts.push(c);
  }
  return alts.slice(0, 3);
}

/**
 * Verse 통계 요약 문자열 (Sheets 대안 컬럼용)
 * e.g. "v_123 | 시편 23:1 | 8회 | 60일 전"
 */
function altSummary(v) {
  if (!v) return '';
  const count = v.show_count || 0;
  const days  = v.last_shown
    ? Math.floor((Date.now() - (v.last_shown.toDate ? v.last_shown.toDate() : new Date(v.last_shown)).getTime()) / 86400000)
    : null;
  const daysStr = days !== null ? `${days}일 전` : '최초';
  return `${v.id} | ${v.reference || ''} | ${count}회 | ${daysStr}`;
}

/**
 * Verse에서 verse_short_ko 가져오기 (필드명 혼용 대응)
 */
function verseShort(v) {
  return v.verse_short_ko || v.verseShortKo || v.verse_short || '';
}

/**
 * Verse에서 verse_full_ko 가져오기 (필드명 혼용 대응)
 */
function verseFull(v) {
  return v.verse_full_ko || v.verseFullKo || v.verse_full || '';
}

/**
 * Verse에서 interpretation 앞 80자 미리보기
 */
function interpPreview(v) {
  const text = v.interpretation || '';
  return text.length > 80 ? text.slice(0, 80) + '...' : text;
}

// ─── [1] previewDailyVerses — 매일 01:00 KST ─────────────────────────────────

exports.previewDailyVerses = onSchedule(
  {
    schedule:  '0 1 * * *',
    timeZone:  'Asia/Seoul',
    region:    'asia-northeast3',
    memory:    '256MiB',
    timeoutSeconds: 120,
  },
  async () => {
    logger.info('🔮 말씀 미리보기 시작 (D/D+1/D+2)');
    await runPreview();
    logger.info('✅ 말씀 미리보기 완료');
  }
);

/** previewDailyVerses 핵심 로직 (HTTP 트리거에서도 재사용) */
async function runPreview() {
  // 1. 전체 구절 로드
  const snap = await db.collection('verses')
    .where('status', '==', 'active')
    .where('curated', '==', true)
    .get();
  const allVerses = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  if (allVerses.length === 0) throw new Error('구절 없음');

  // 2. D(오늘) — 이미 app_config/today_verse에 있으면 그걸 사용
  const d0 = kstDateOffset(0);
  const todayDoc = await db.collection('app_config').doc('today_verse').get();
  const todayData = todayDoc.exists ? todayDoc.data() : null;

  const selectedIds = [];
  const schedules   = [];

  // D: 오늘 (이미 확정된 말씀)
  if (todayData && todayData.date === d0.dateStr && todayData.verse_id) {
    const v = allVerses.find(x => x.id === todayData.verse_id);
    if (v) {
      selectedIds.push(v.id);
      schedules.push({ offset: 0, dateStr: d0.dateStr, dayInt: d0.dayInt, verse: v, alts: [] });
    }
  } else {
    const v = pickVerse(allVerses, d0.dayInt, []);
    if (v) {
      selectedIds.push(v.id);
      schedules.push({ offset: 0, dateStr: d0.dateStr, dayInt: d0.dayInt, verse: v, alts: [] });
    }
  }

  // D+1, D+2
  for (let offset = 1; offset <= 2; offset++) {
    const dx      = kstDateOffset(offset);

    // verse_schedule에 이미 override가 있으면 그 id 우선
    const existing = await db.collection('verse_schedule').doc(dx.dateStr).get();
    let verse;
    if (existing.exists && existing.data().status === 'override' && existing.data().verse_id) {
      verse = allVerses.find(x => x.id === existing.data().verse_id) || pickVerse(allVerses, dx.dayInt, selectedIds);
    } else {
      verse = pickVerse(allVerses, dx.dayInt, selectedIds);
    }

    if (!verse) continue;
    selectedIds.push(verse.id);
    const alts = pickAlternatives(allVerses, dx.dayInt, verse.id, selectedIds);
    schedules.push({ offset, dateStr: dx.dateStr, dayInt: dx.dayInt, verse, alts });
  }

  // 3. Firestore verse_schedule 업데이트 (D는 read-only 참조용, D+1/D+2는 편집 가능)
  const batch = db.batch();
  for (const s of schedules) {
    const ref  = db.collection('verse_schedule').doc(s.dateStr);
    const snap = await ref.get();

    // 이미 override 상태면 그 verse_id 유지, auto만 덮어씀
    if (snap.exists && snap.data().status === 'override') continue;

    const now = admin.firestore.FieldValue.serverTimestamp();
    const now2 = new Date();

    // cooldown 체크
    const v = s.verse;
    const lastShown = v.last_shown
      ? (v.last_shown.toDate ? v.last_shown.toDate() : new Date(v.last_shown))
      : null;
    const daysSince = lastShown ? Math.floor((now2 - lastShown) / 86400000) : null;
    const cooldown  = typeof v.cooldown_days === 'number' ? v.cooldown_days : 7;

    batch.set(ref, {
      verse_id:       v.id,
      date:           s.dateStr,
      day_offset:     s.offset,
      reference:      v.reference    || '',
      verse_short:    verseShort(v),
      verse_full:     verseFull(v),
      interpretation: interpPreview(v),
      theme:          (v.theme || []).join(', '),
      show_count:     v.show_count   || 0,
      last_shown:     lastShown ? lastShown.toISOString().slice(0, 10) : '최초',
      days_since:     daysSince !== null ? daysSince : 9999,
      cooldown_days:  cooldown,
      cooldown_ok:    daysSince === null || daysSince >= cooldown,
      alt_1:          altSummary(s.alts[0]),
      alt_2:          altSummary(s.alts[1]),
      alt_3:          altSummary(s.alts[2]),
      alt_1_id:       s.alts[0]?.id || '',
      alt_2_id:       s.alts[1]?.id || '',
      alt_3_id:       s.alts[2]?.id || '',
      status:         s.offset === 0 ? 'active' : 'scheduled',
      preview_at:     now,
      notes:          '',
    }, { merge: false });
  }
  await batch.commit();
  return schedules;
}

// ─── [2] selectDailyVerse — 매일 04:00 KST ──────────────────────────────────

exports.selectDailyVerse = onSchedule(
  {
    schedule:  '0 4 * * *',
    timeZone:  'Asia/Seoul',
    region:    'asia-northeast3',
    memory:    '256MiB',
    timeoutSeconds: 60,
  },
  async () => {
    logger.info('📖 오늘의 말씀 선택 시작');

    const { dateStr, dayInt } = kstDateOffset(0);

    // 1. 전체 구절 로드
    const snap = await db.collection('verses')
      .where('status', '==', 'active')
      .where('curated', '==', true)
      .get();
    const allVerses = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    if (allVerses.length === 0) {
      logger.error('❌ 구절 없음');
      return;
    }

    // 2. verse_schedule/{today} 먼저 확인 (관리자 선정 또는 미리보기)
    let selected = null;
    const scheduleDoc = await db.collection('verse_schedule').doc(dateStr).get();
    if (scheduleDoc.exists) {
      const sData = scheduleDoc.data();
      const scheduledVerse = allVerses.find(v => v.id === sData.verse_id);
      if (scheduledVerse) {
        selected = scheduledVerse;
        logger.info(`📋 verse_schedule 사용: ${selected.id} (${sData.status})`);
      }
    }

    // 3. 없으면 알고리즘
    if (!selected) {
      selected = pickVerse(allVerses, dayInt, []);
      logger.info(`🎲 알고리즘 선택: ${selected.id}`);
    }

    // 4. app_config/today_verse 업데이트
    await db.collection('app_config').doc('today_verse').set({
      verse_id:     selected.id,
      date:         dateStr,
      reference:    selected.reference    || '',
      verse_short:  verseShort(selected),
      selected_at:  admin.firestore.FieldValue.serverTimestamp(),
      source:       scheduleDoc.exists ? scheduleDoc.data().status : 'algorithm',
    });

    // 5. verse_schedule 상태 → active
    await db.collection('verse_schedule').doc(dateStr).set(
      { status: 'active', activated_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    ).catch(() => {});

    // 6. show_count 업데이트
    await db.collection('verses').doc(selected.id).update({
      last_shown:  admin.firestore.FieldValue.serverTimestamp(),
      show_count:  admin.firestore.FieldValue.increment(1),
    }).catch(e => logger.warn('show_count 업데이트 실패:', e.message));

    // 7. 미리보기 갱신 (D+1, D+2 스케줄 업데이트)
    try {
      await runPreview();
      logger.info('🔄 미리보기 자동 갱신 완료');
    } catch (e) {
      logger.warn('미리보기 갱신 실패 (무시):', e.message);
    }

    logger.info(`✅ 오늘의 말씀: ${selected.id} | ${selected.reference} | ${dateStr}`);
  }
);

// ─── [3] getVerseSchedule — HTTP GET ─────────────────────────────────────────

exports.getVerseSchedule = onRequest(
  { region: 'asia-northeast3', cors: true },
  async (req, res) => {
    if (req.method !== 'GET') { res.status(405).send('Method Not Allowed'); return; }

    try {
      const dates = [kstDateOffset(0), kstDateOffset(1), kstDateOffset(2)];
      const dayLabels = ['D (오늘)', 'D+1', 'D+2'];
      const result = [];

      for (let i = 0; i < dates.length; i++) {
        const { dateStr } = dates[i];
        const doc = await db.collection('verse_schedule').doc(dateStr).get();
        if (doc.exists) {
          result.push({ day_label: dayLabels[i], ...doc.data() });
        } else {
          result.push({ day_label: dayLabels[i], date: dateStr, status: 'not_scheduled' });
        }
      }

      res.status(200).json({ schedules: result, generated_at: new Date().toISOString() });
    } catch (e) {
      logger.error('getVerseSchedule 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  }
);

// ─── [4] applyVerseOverrides — HTTP POST (Apps Script "적용하기" 버튼) ────────

exports.applyVerseOverrides = onRequest(
  { region: 'asia-northeast3', cors: true },
  async (req, res) => {
    if (req.method !== 'POST') { res.status(405).send('Method Not Allowed'); return; }

    try {
      const { overrides } = req.body; // [{ date, selection, notes }]
      if (!Array.isArray(overrides) || overrides.length === 0) {
        res.status(400).json({ error: 'overrides 배열 필요' });
        return;
      }

      const results = [];
      for (const o of overrides) {
        const { date, selection, notes } = o;
        if (!date || !selection) continue;

        const scheduleRef = db.collection('verse_schedule').doc(date);
        const scheduleDoc = await scheduleRef.get();
        if (!scheduleDoc.exists) {
          results.push({ date, status: 'error', message: 'schedule 없음' });
          continue;
        }

        const sData = scheduleDoc.data();

        // selection 해석: 1=auto, 2=alt_1, 3=alt_2, 4=alt_3
        const selNum = parseInt(selection, 10);
        let targetVerseId = sData.verse_id; // default: auto
        if (selNum === 2 && sData.alt_1_id) targetVerseId = sData.alt_1_id;
        if (selNum === 3 && sData.alt_2_id) targetVerseId = sData.alt_2_id;
        if (selNum === 4 && sData.alt_3_id) targetVerseId = sData.alt_3_id;
        // 문자열 ID 직접 입력 (selNum이 NaN이거나 5 이상)
        if (isNaN(selNum) || selNum >= 5) {
          const directId = String(selection).trim();
          if (directId.startsWith('v_')) targetVerseId = directId;
        }

        const isOverride = selNum !== 1 && targetVerseId !== sData.verse_id;

        // 대상 verse 정보 가져오기
        const verseDoc = await db.collection('verses').doc(targetVerseId).get();
        const vData    = verseDoc.exists ? verseDoc.data() : {};

        await scheduleRef.update({
          verse_id:           targetVerseId,
          reference:          vData.reference    || sData.reference,
          verse_short:        verseShort(vData)  || sData.verse_short,
          verse_full:         verseFull(vData)   || sData.verse_full || '',
          interpretation:     interpPreview(vData) || sData.interpretation,
          status:             isOverride ? 'override' : 'scheduled',
          override_selection: selNum,
          notes:              notes || '',
          applied_at:         admin.firestore.FieldValue.serverTimestamp(),
        });

        results.push({
          date,
          status:    'ok',
          verse_id:  targetVerseId,
          reference: vData.reference || '알 수 없음',
          is_override: isOverride,
        });
        logger.info(`✅ override 적용: ${date} → ${targetVerseId} (selection=${selNum})`);
      }

      res.status(200).json({ results });
    } catch (e) {
      logger.error('applyVerseOverrides 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  }
);

// ─── [5] triggerPreview — HTTP GET (수동 미리보기 강제 갱신) ─────────────────

exports.triggerPreview = onRequest(
  { region: 'asia-northeast3', cors: true },
  async (req, res) => {
    if (req.method !== 'GET') { res.status(405).send('Method Not Allowed'); return; }
    try {
      const schedules = await runPreview();
      res.status(200).json({
        message: '미리보기 갱신 완료',
        dates: schedules.map(s => `${s.dateStr}: ${s.verse.reference}`),
      });
    } catch (e) {
      logger.error('triggerPreview 오류:', e.message);
      res.status(500).json({ error: e.message });
    }
  }
);

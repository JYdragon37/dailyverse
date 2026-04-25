// sync_home_greetings.js
// Google Sheets HOME_GREETINGS 탭 → Firestore greetings 컬렉션 완전 동기화
// Design Ref: §5 — 업로드 스크립트

const { google } = require('googleapis');
const admin = require('firebase-admin');
const key = require('./serviceAccountKey.json');

// Firestore 초기화
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(key),
    });
}
const db = admin.firestore();

// Sheets 인증
const sheetsAuth = new google.auth.GoogleAuth({
    credentials: key,
    scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
});

const SPREADSHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'HOME_GREETINGS'; // 탭명: HOME_GREETINGS

async function main() {
    const client = await sheetsAuth.getClient();
    const sheets = google.sheets({ version: 'v4', auth: client });

    // 1. 전체 데이터 동적 읽기 (헤더 포함, 행 수 무제한)
    const response = await sheets.spreadsheets.values.get({
        spreadsheetId: SPREADSHEET_ID,
        range: `${SHEET_NAME}!A:G`,
    });

    const allRows = response.data.values || [];
    console.log(`총 ${allRows.length}개 행 읽음 (헤더 포함)`);

    // 2. 헤더 행 자동 탐지: gr_id 컬럼이 있는 행을 헤더로 판단
    let headerRowIndex = -1;
    for (let i = 0; i < Math.min(allRows.length, 10); i++) {
        const row = allRows[i];
        if (row.some(cell => typeof cell === 'string' && cell.toLowerCase().includes('gr_id'))) {
            headerRowIndex = i;
            break;
        }
    }

    // gr_id 헤더를 못 찾으면 행 2(index 2)를 데이터 시작으로 간주 (기존 구조 유지)
    const dataStartIndex = headerRowIndex >= 0 ? headerRowIndex + 1 : 2;
    const rows = allRows.slice(dataStartIndex);
    console.log(`헤더 행: ${headerRowIndex >= 0 ? headerRowIndex + 1 : '미탐지(기본값 3행)'}, 데이터 시작: ${dataStartIndex + 1}행, 데이터 행 수: ${rows.length}`);

    // 3. 데이터 변환
    const greetings = [];
    for (const row of rows) {
        const zoneId    = (row[2] || '').trim();            // C열: zone_id (수식 결과)
        const langRaw   = (row[3] || '').trim();            // D열: Language
        const text      = (row[4] || '').trim();            // E열: 인사말
        const charCount = parseInt(row[5] || '0', 10);      // F열: 자수
        const grId      = (row[6] || '').trim();            // G열: gr_id

        if (!zoneId || !text || !grId) continue;

        const language = langRaw.toLowerCase().includes('eng') ? 'en' : 'ko';

        greetings.push({ grId, zoneId, language, text, charCount });
    }

    console.log(`유효한 greeting ${greetings.length}개`);

    // 4. Sheets gr_id 집합 수집
    const sheetsIds = new Set(greetings.map(g => g.grId));

    // 5. Firestore 기존 문서 목록 수집
    const existingSnap = await db.collection('greetings').get();
    const existingIds = existingSnap.docs.map(d => d.id);
    console.log(`Firestore 기존 문서: ${existingIds.length}개`);

    // 6. Sheets에 없는 Firestore 문서 삭제
    const toDelete = existingIds.filter(id => !sheetsIds.has(id));
    console.log(`삭제 대상: ${toDelete.length}개`);

    const BATCH_SIZE = 499;

    for (let i = 0; i < toDelete.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const chunk = toDelete.slice(i, i + BATCH_SIZE);
        for (const id of chunk) {
            batch.delete(db.collection('greetings').doc(id));
        }
        await batch.commit();
        console.log(`삭제 완료: ${Math.min(i + BATCH_SIZE, toDelete.length)}/${toDelete.length}`);
    }

    // 7. Sheets 데이터 upsert
    let uploaded = 0;

    for (let i = 0; i < greetings.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const chunk = greetings.slice(i, i + BATCH_SIZE);

        for (const g of chunk) {
            const ref = db.collection('greetings').doc(g.grId);
            batch.set(ref, {
                gr_id:      g.grId,
                zone_id:    g.zoneId,
                language:   g.language,
                text:       g.text,
                char_count: g.charCount,
            });
        }

        await batch.commit();
        uploaded += chunk.length;
        console.log(`업로드: ${uploaded}/${greetings.length}`);
    }

    console.log(`\n✅ 완료: upsert ${uploaded}개, 삭제 ${toDelete.length}개`);

    // 8. 샘플 확인
    const snap = await db.collection('greetings')
        .where('zone_id', '==', 'deep_dark')
        .where('language', '==', 'ko')
        .limit(3)
        .get();
    console.log('\n[샘플] deep_dark/ko:');
    snap.docs.forEach(d => console.log(' -', d.data().text));
}

main().catch(console.error);

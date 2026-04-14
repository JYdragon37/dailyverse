// upload_greetings.js
// Google Sheets greeting 탭 → Firestore greetings 컬렉션 업로드
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
const RANGE = 'greeting!A3:G178'; // Zone, 시간, id(zone_id), Language, 인사말, 자수, gr_id

async function main() {
    const client = await sheetsAuth.getClient();
    const sheets = google.sheets({ version: 'v4', auth: client });

    const response = await sheets.spreadsheets.values.get({
        spreadsheetId: SPREADSHEET_ID,
        range: RANGE,
    });

    const rows = response.data.values || [];
    console.log(`총 ${rows.length}개 행 읽음`);

    // 데이터 변환
    const greetings = [];
    for (const row of rows) {
        const zoneId   = (row[2] || '').trim();   // C열: zone_id (수식 결과)
        const langRaw  = (row[3] || '').trim();   // D열: Language
        const text     = (row[4] || '').trim();   // E열: 인사말
        const charCount = parseInt(row[5] || '0', 10); // F열: 자수
        const grId     = (row[6] || '').trim();   // G열: gr_id

        if (!zoneId || !text || !grId) continue;

        const language = langRaw.toLowerCase().includes('eng') ? 'en' : 'ko';

        greetings.push({ grId, zoneId, language, text, charCount });
    }

    console.log(`유효한 greeting ${greetings.length}개`);

    // Firestore batch write (500개 단위)
    const BATCH_SIZE = 499;
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

    console.log(`\n✅ 완료: 총 ${uploaded}개 greetings 업로드됨`);

    // 샘플 확인
    const snap = await db.collection('greetings')
        .where('zone_id', '==', 'deep_dark')
        .where('language', '==', 'ko')
        .limit(3)
        .get();
    console.log('\n[샘플] deep_dark/ko:');
    snap.docs.forEach(d => console.log(' -', d.data().text));
}

main().catch(console.error);

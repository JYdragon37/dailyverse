/**
 * setup_app_config.js
 * Firestore app_config 컬렉션 초기 문서 생성
 * - minimum_version: 강제 업데이트 제어
 * - master_accounts: 마스터 계정 관리
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
db.settings({ preferRest: true });

async function setupAppConfig() {
  console.log('🔧 app_config 문서 생성 시작...\n');

  // 1. minimum_version — 강제 업데이트 제어
  const minVersionRef = db.collection('app_config').doc('minimum_version');
  const minVersionSnap = await minVersionRef.get();

  if (minVersionSnap.exists) {
    console.log('⚠️  minimum_version 이미 존재:', minVersionSnap.data());
    console.log('   → 덮어쓰지 않음 (수동으로 수정하려면 Firebase 콘솔 사용)\n');
  } else {
    await minVersionRef.set({
      ios: '1.0.0',
      force_update: false
    });
    console.log('✅ minimum_version 생성 완료');
    console.log('   ios: "1.0.0", force_update: false\n');
  }

  // 2. master_accounts — 프리미엄 자동 적용 계정
  const masterRef = db.collection('app_config').doc('master_accounts');
  const masterSnap = await masterRef.get();

  if (masterSnap.exists) {
    console.log('⚠️  master_accounts 이미 존재:', masterSnap.data());
    console.log('   → 덮어쓰지 않음 (수동으로 수정하려면 Firebase 콘솔 사용)\n');
  } else {
    await masterRef.set({
      emails: [
        'huhjungyong@gmail.com',
        'highkick370@gmail.com'
      ]
    });
    console.log('✅ master_accounts 생성 완료');
    console.log('   emails: ["huhjungyong@gmail.com", "highkick370@gmail.com"]\n');
  }

  console.log('🎉 완료! Firebase 콘솔에서 확인하세요.');
  console.log('   https://console.firebase.google.com → Firestore → app_config');
  process.exit(0);
}

setupAppConfig().catch(err => {
  console.error('❌ 오류:', err.message);
  process.exit(1);
});

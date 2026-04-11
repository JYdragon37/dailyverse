const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const ids = [];
for (let i = 51; i <= 71; i++) ids.push(`v_${String(i).padStart(3,'0')}`);

async function main() {
  for (const id of ids) {
    const doc = await db.collection('verses').doc(id).get();
    if (doc.exists) {
      const d = doc.data();
      console.log(`\n=== ${id} ===`);
      console.log(`reference: ${d.reference}`);
      console.log(`text_ko: ${d.text_ko}`);
      console.log(`theme: ${JSON.stringify(d.theme)}`);
      console.log(`mode: ${JSON.stringify(d.mode)}`);
      console.log(`interpretation: ${d.interpretation}`);
      console.log(`application: ${d.application}`);
    } else {
      console.log(`\n=== ${id} === NOT FOUND`);
    }
  }
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });

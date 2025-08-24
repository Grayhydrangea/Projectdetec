// backend/admin-tools/set-claims.js
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

if (process.argv.length < 4) {
  console.log('Usage: node admin-tools/set-claims.js <uid> <role>');
  console.log('role = admin | guard | security | student');
  process.exit(1);
}

const [, , uid, role] = process.argv;

// ชี้ไปที่ไฟล์คีย์ที่คุณเพิ่งดาวน์โหลด
const keyPath = path.resolve(__dirname, '../firebase/serviceAccountKey.json');

// อ่าน "เนื้อ" JSON จริง ๆ
let serviceAccount;
try {
  serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
} catch (e) {
  console.error('❌ อ่านไฟล์ serviceAccountKey.json ไม่ได้:', e.message);
  process.exit(1);
}

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} catch (e) {
  console.error('❌ initializeApp ล้มเหลว:', e);
  process.exit(1);
}

(async () => {
  try {
    // ตั้ง custom claims
    await admin.auth().setCustomUserClaims(uid, { role });

    // อ่านกลับมายืนยัน
    const user = await admin.auth().getUser(uid);
    console.log('✅ ตั้ง role สำเร็จ:', { uid: user.uid, role: user.customClaims?.role });

    console.log('ℹ️ ผู้ใช้ต้อง logout/login ใหม่ หรือเรียก getIdToken(true) เพื่อ refresh claims');
    process.exit(0);
  } catch (e) {
    console.error('❌ Failed:', e);
    process.exit(1);
  }
})();


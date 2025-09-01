// controllers/authControllers.js
const { auth, db, admin } = require('../firebase/firebase');

// helper: normalize ป้ายทะเบียน (ลบช่องว่าง, ขีด, uppercase)
function normalizePlate(p = '') {
  return p.toString().trim().replace(/\s+/g, '').replace(/-/g, '').toUpperCase();
}

// ---------------- REGISTER ----------------
exports.register = async (req, res) => {
  try {
    const { email, password, name, phone, role, plate } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: 'email & password required' });
    }

    // สร้าง user ใน Firebase Authentication
    const createRes = await auth.createUser({
      email,
      password,
      displayName: name || email,
    });
    const uid = createRes.uid;

    const now = admin.firestore.Timestamp.now();
    const roleSafe = (role || 'student').toLowerCase();

    // set custom claims สำหรับ role
    await auth.setCustomUserClaims(uid, { role: roleSafe });

    // เตรียมข้อมูล user
    const plateNorm = plate ? normalizePlate(plate) : '';
    const userData = {
      uid,
      email,
      name: name || email,
      phone: phone || '',
      role: roleSafe,
      licensePlate: plate || '',     // 👉 บันทึกใน users
      plateNormalized: plateNorm,    // 👉 บันทึกใน users
      createdAt: now,
      updatedAt: now,
    };

    // บันทึก users/{uid}
    await db.collection('users').doc(uid).set(userData, { merge: true });

    // ถ้ามี plate → บันทึก license_plates/{plateNormalized}
    if (plate && plateNorm) {
      await db.collection('license_plates').doc(plateNorm).set(
        {
          plate: plate,
          plateNormalized: plateNorm,
          ownerUid: uid,
          registeredAt: now,
        },
        { merge: true }
      );
    }

    // สร้าง custom token ส่งกลับให้ Flutter ใช้ login
    const customToken = await auth.createCustomToken(uid, { role: roleSafe });

    return res.json({ uid, customToken });
  } catch (e) {
    console.error('register error', e);
    return res.status(500).json({ error: e.message });
  }
};

// ---------------- LOGIN ----------------
exports.login = async (req, res) => {
  try {
    const { uid } = req.body;
    if (!uid) return res.status(400).json({ error: 'uid required' });

    const user = await auth.getUser(uid);
    const role = user.customClaims?.role || 'student';

    const customToken = await auth.createCustomToken(uid, { role });
    return res.json({ uid, customToken });
  } catch (e) {
    console.error('login error', e);
    return res.status(500).json({ error: e.message });
  }
};

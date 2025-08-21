const axios = require('axios');
const { admin, db, auth } = require('../firebase/firebase');

const DEV = process.env.NODE_ENV !== 'production';

// ---------- REGISTER ----------
exports.register = async (req, res) => {
  try {
    const { email, password, name, phone, role, plate } = req.body;

    // Log ข้อมูลเข้า (ระวัง password)
    console.log('[REGISTER req]', { email, name, phone, role, plate });

    // Validation พื้นฐาน
    if (!email || !password || !name || !phone || !role) {
      return res.status(400).json({ error: 'Missing required fields: email, password, name, phone, role' });
    }
    const allowed = ['student', 'guard', 'admin'];
    if (!allowed.includes(role)) {
      return res.status(400).json({ error: `Invalid role. Allowed: ${allowed.join(', ')}` });
    }
    if (role === 'student' && !plate) {
      return res.status(400).json({ error: 'Plate is required for role "student"' });
    }
    // กัน plate ซ้ำ
    if (role === 'student' && plate) {
      const plateDoc = await db.collection('license_plates').doc(plate).get();
      if (plateDoc.exists) return res.status(409).json({ error: 'License plate already registered' });
    }

    // สร้าง user ใน Firebase Auth
    const userRecord = await auth.createUser({
      email,
      password,            // >= 6 chars
      displayName: name,
      disabled: false,
    });
    const uid = userRecord.uid;

    // ตั้ง custom claims
    await auth.setCustomUserClaims(uid, { role });

    // เขียน Firestore
    const batch = db.batch();
    batch.set(db.collection('users').doc(uid), {
      uid, name, phone, email, role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    if (role === 'student' && plate) {
      batch.set(db.collection('license_plates').doc(plate), {
        plate, ownerUid: uid,
        registeredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    return res.status(201).json({ uid });
  } catch (err) {
    // พิมพ์ error ทั้งหมดลง console
    console.error('[Register Error]', {
      code: err?.code,
      message: err?.message,
      stack: err?.stack,
    });

    // map เป็นข้อความอ่านง่าย + โชว์รายละเอียดเมื่อ DEV
    if (err?.code === 'auth/email-already-exists') {
      return res.status(409).json({ error: 'Email already exists' });
    }
    if (err?.code === 'auth/invalid-password') {
      return res.status(400).json({ error: 'Invalid password (min 6 chars)' });
    }
    if (err?.code === 'auth/invalid-email') {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    return res.status(500).json({
      error: 'Register failed',
      ...(DEV ? { code: err?.code, message: err?.message } : {}),
    });
  }
};

// ---------- LOGIN ----------
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!process.env.FIREBASE_API_KEY) {
      return res.status(500).json({ error: 'Missing FIREBASE_API_KEY on server' });
    }
    const r = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${process.env.FIREBASE_API_KEY}`,
      { email, password, returnSecureToken: true }
    );
    return res.status(200).json({ idToken: r.data.idToken, uid: r.data.localId });
  } catch (err) {
    console.error('[Login Error]', err.response?.data || err.message);
    return res.status(401).json({ error: 'Invalid email or password' });
  }
};
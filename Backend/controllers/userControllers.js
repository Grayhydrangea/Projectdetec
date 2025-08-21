const { db, auth } = require('../firebase/firebase');
// ✅ หน้าหลัก (ดึง log ล่าสุดของรถนิสิต)
exports.getDashboard = async (req, res) => {
 try {
   const { uid } = req.params;
   // ดึงทะเบียนรถของนิสิต
   const plateSnap = await db.collection('license_plates')
     .where('ownerUid', '==', uid).get();
   if (plateSnap.empty) return res.status(404).json({ error: 'No plate found' });
   const plate = plateSnap.docs[0].id;
   // ดึง log ล่าสุด
   const logsSnap = await db.collection('logs')
     .where('plate', '==', plate)
     .orderBy('timestamp', 'desc')
     .limit(1)
     .get();
   const latestLog = logsSnap.empty ? null : logsSnap.docs[0].data();
   res.json({ plate, latestLog });
 } catch (err) {
   res.status(500).json({ error: err.message });
 }
};
// ✅ ดูประวัติการเข้าออก
exports.getHistory = async (req, res) => {
 try {
   const { uid } = req.params;
   const plateSnap = await db.collection('license_plates')
     .where('ownerUid', '==', uid).get();
   if (plateSnap.empty) return res.status(404).json({ error: 'No plate found' });
   const plate = plateSnap.docs[0].id;
   const logsSnap = await db.collection('logs')
     .where('plate', '==', plate)
     .orderBy('timestamp', 'desc')
     .get();
   const logs = logsSnap.docs.map(doc => doc.data());
   res.json({ plate, logs });
 } catch (err) {
   res.status(500).json({ error: err.message });
 }
};
// ✅ รายงานการเข้าออก
exports.getReports = async (req, res) => {
 try {
   const { date } = req.query; // ?date=2025-07-06
   let reportDoc;
   if (date) {
     reportDoc = await db.collection('reports').doc(date).get();
     if (!reportDoc.exists) return res.status(404).json({ error: 'No report found' });
     return res.json(reportDoc.data());
   }
   // รายงานล่าสุด
   const reportsSnap = await db.collection('reports')
     .orderBy('date', 'desc').limit(1).get();
   if (reportsSnap.empty) return res.status(404).json({ error: 'No reports found' });
   res.json(reportsSnap.docs[0].data());
 } catch (err) {
   res.status(500).json({ error: err.message });
 }
};
// ✅ การแจ้งเตือนนิสิต (รถของตัวเอง)
exports.getNotifications = async (req, res) => {
 try {
   const { uid } = req.params;
   const plateSnap = await db.collection('license_plates')
     .where('ownerUid', '==', uid).get();
   if (plateSnap.empty) return res.json({ notifications: [] });
   const plate = plateSnap.docs[0].id;
   const logsSnap = await db.collection('logs')
     .where('plate', '==', plate)
     .orderBy('timestamp', 'desc')
     .limit(10).get();
   const logs = logsSnap.docs.map(d => d.data());
   res.json({ notifications: logs });
 } catch (err) {
   res.status(500).json({ error: err.message });
 }
};
// ✅ โปรไฟล์
exports.getProfile = async (req, res) => {
 try {
   const { uid } = req.params;
   const userDoc = await db.collection('users').doc(uid).get();
   if (!userDoc.exists) return res.status(404).json({ error: 'User not found' });
   res.json(userDoc.data());
 } catch (err) {
   res.status(500).json({ error: err.message });
 }
};
// ✅ การตั้งค่า (แก้ไขชื่อ, เบอร์, รหัสผ่าน)
exports.updateProfile = async (req, res) => {
 try {
   const { uid } = req.params;
   const { name, phone, password } = req.body;
   if (name || phone) {
     await db.collection('users').doc(uid).update({ name, phone });
   }
   if (password) {
     await auth.updateUser(uid, { password });
   }
   res.json({ success: true });
 } catch (err) {
   res.status(500).json({ error: err.message });
 }
};
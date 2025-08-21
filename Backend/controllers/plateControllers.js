exports.detectPlate = async (req, res) => {
 const { plate, location } = req.body;
 const plateDoc = await db.collection('license_plates').doc(plate).get();
 const log = {
   plate,
   location,
   timestamp: new Date()
 };
 await db.collection('logs').add(log);
 if (plateDoc.exists) {
   const ownerUid = plateDoc.data().ownerUid;
   const user = await db.collection('users').doc(ownerUid).get();
   return res.status(200).json({ notify: 'student', data: user.data() });
 } else {
   return res.status(200).json({ notify: 'guard' });
 }
};
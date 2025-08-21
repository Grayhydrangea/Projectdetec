exports.generateDailyReport = async (dateStr) => {
 const dayOfWeek = new Date(dateStr).toLocaleString('en-TH', { weekday: 'long' }).toLowerCase();
 const guards = await db.collection('shift_templates').get();
 const morningGuards = [];
 const afternoonGuards = [];
 guards.forEach(doc => {
   const data = doc.data();
   if (data.schedule?.[dayOfWeek] === 'morning') {
     morningGuards.push({ uid: doc.id, name: data.name });
   } else if (data.schedule?.[dayOfWeek] === 'afternoon') {
     afternoonGuards.push({ uid: doc.id, name: data.name });
   }
 });
 const logsSnap = await db.collection('logs')
   .where('timestamp', '>=', new Date(dateStr))
   .where('timestamp', '<', new Date(new Date(dateStr).getTime() + 86400000))
   .get();
 const total = logsSnap.size;
 const entries = logsSnap.docs.filter(d => d.data().status === 'in').length;
 const exits = total - entries;
 await db.collection('reports').doc(dateStr).set({
   date: dateStr,
   location: 'ประตูหน้า',
   totalVehicles: total,
   entries,
   exits,
   morningGuards,
   afternoonGuards,
   summaryCreatedAt: new Date()
 });
};
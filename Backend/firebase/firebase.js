const admin = require('firebase-admin');

try {
  if (!admin.apps.length) {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
      storageBucket: 'motodetec-entry-exit.appspot.com',
    });
    console.log('✅ Firebase initialized:', serviceAccount.project_id);
  }
} catch (error) {
  console.error('Firebase initialization error:', error);
  throw error;
}

const db = admin.firestore();
const auth = admin.auth();
db.settings({ ignoreUndefinedProperties: true });

console.log('Admin app project:', admin.app().options.projectId);

module.exports = { admin, db, auth };
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const fcm = admin.messaging();

    if (!data.toUid || !data.title || !data.body) return;

    const userDoc = await admin.firestore().collection("users").doc(data.toUid).get();
    const token = userDoc.data()?.fcmToken;

    if (!token) return;

    const payload = {
      notification: {
        title: data.title,
        body: data.body,
        sound: "alert.mp3"
      },
      token: token
    };

    try {
      await fcm.send(payload);
      console.log("📬 Notification sent to", data.toUid);
    } catch (err) {
      console.error("❌ Failed to send FCM:", err);
    }
  });

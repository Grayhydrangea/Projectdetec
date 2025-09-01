// controllers/cameraControllers.js
const { db, admin } = require("../firebase/firebase");

/**
 * รับเหตุการณ์จากกล้อง
 * body: { plateText, locationId, status }
 */
async function handleCameraEvent(req, res) {
  try {
    const { plateText, locationId = "gate1", status = "entry" } = req.body || {};
    if (!plateText || typeof plateText !== "string") {
      return res.status(400).json({ error: "plateText required" });
    }

    const now = admin.firestore.Timestamp.now();
    const plateNormalized = plateText.trim().toUpperCase();

    // หาเจ้าของป้ายใน license_plates
    const plateSnap = await db
      .collection("license_plates")
      .where("plateNormalized", "==", plateNormalized)
      .limit(1)
      .get();

    if (!plateSnap.empty) {
      // === ลงทะเบียนแล้ว ===
      const plateDoc = plateSnap.docs[0].data();
      const ownerUid = plateDoc.ownerUid; // ต้องมีในเอกสาร license_plates

      // บันทึก attendance
      await db.collection("attendance").add({
        uid: ownerUid,
        licensePlate: plateNormalized,
        plateNormalized,
        locationId,
        status,              // "entry" | "exit"
        isRegistered: true,
        time: now,
        createdAt: now,
      });

      // แจ้งนิสิตผู้เป็นเจ้าของ
      await db.collection("notifications").add({
        toUid: ownerUid,
        title: status === "entry" ? "รถของคุณเข้า" : "รถของคุณออก",
        body: `ป้าย ${plateNormalized} ที่ ${locationId}`,
        type: status,
        read: false,
        createdAt: now,
      });

      return res.json({ ok: true, registered: true });
    }

    // === ไม่ได้ลงทะเบียน ===
    // บันทึก attendance ด้วย isRegistered: false
    await db.collection("attendance").add({
      uid: "", // ว่างเพื่อไม่นับเป็นของนิสิต
      licensePlate: plateNormalized,
      plateNormalized,
      locationId,
      status,
      isRegistered: false,
      time: now,
      createdAt: now,
    });

    // แจ้งเตือนยาม/รปภ.
    const guards = await db
      .collection("users")
      .where("role", "in", ["guard", "security"])
      .get();

    const batch = db.batch();
    guards.forEach((doc) => {
      batch.set(db.collection("notifications").doc(), {
        toUid: doc.id,
        title: "พบรถไม่ได้ลงทะเบียน",
        body: `ป้าย ${plateNormalized} ที่ ${locationId}`,
        type: "unregistered",
        read: false,
        createdAt: now,
      });
    });
    await batch.commit();

    return res.json({ ok: true, registered: false });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: e.message });
  }
}

// ✅ export แบบ CommonJS
module.exports = { handleCameraEvent };

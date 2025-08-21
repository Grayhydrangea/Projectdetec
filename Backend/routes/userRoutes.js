const express = require('express');
const router = express.Router();
const {
 getDashboard,
 getHistory,
 getReports,
 getNotifications,
 getProfile,
 updateProfile
} = require('../controllers/userControllers');
// Dashboard หน้าหลัก
router.get('/dashboard/:uid', getDashboard);
// ประวัติการเข้าออก
router.get('/history/:uid', getHistory);
// รายงานการเข้าออก
router.get('/reports', getReports);
// แจ้งเตือน
router.get('/notifications/:uid', getNotifications);
// ข้อมูลโปรไฟล์
router.get('/profile/:uid', getProfile);
// แก้ไขโปรไฟล์
router.put('/profile/:uid', updateProfile);
module.exports = router;
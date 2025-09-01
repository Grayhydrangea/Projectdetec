// routes/authRoutes.js
const express = require('express');
const router = express.Router();

// ✅ import controller
const authController = require('../controllers/authControllers');

// สมัครสมาชิก
router.post('/register', authController.register);

// ล็อกอิน
router.post('/login', authController.login);

module.exports = router;

// routes/cameraRoutes.js
const express = require('express');
const { handleCameraEvent } = require('../controllers/cameraControllers');

const router = express.Router();

// POST /api/camera/event
router.post('/camera/event', handleCameraEvent);

module.exports = router;


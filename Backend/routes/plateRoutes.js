const express = require('express');
const router = express.Router();
const { detectPlate } = require('../controllers/plateControllers');
router.post('/detect', detectPlate);
module.exports = router;
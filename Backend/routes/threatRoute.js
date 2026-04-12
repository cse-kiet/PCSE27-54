const express = require('express');
const router = express.Router();
const { sendThreatAlert, reportThreat } = require('../controllers/threatController');
const { authMiddleware } = require('../middleware/authMiddleware');

// Send threat alert to emergency contacts
router.post('/alert', authMiddleware, sendThreatAlert);

// Report threat incident for logging/analytics
router.post('/report', authMiddleware, reportThreat);

module.exports = router;

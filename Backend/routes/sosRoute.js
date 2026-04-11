const express = require('express');
const router = express.Router();
const { sendSosAlert } = require('../controllers/sosController');
const { authMiddleware } = require('../middleware/authMiddleware');

router.post('/send', authMiddleware, sendSosAlert);

module.exports = router;

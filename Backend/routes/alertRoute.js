const express = require("express");
const router = express.Router();

const {
  startAlert,
  stopAlert,
  getCurrentAlert
} = require("../controllers/alertController");

const { authMiddleware } = require("../middleware/authMiddleware");


// Start an alert when a risky situation is detected
router.post("/start", authMiddleware, startAlert);


// Stop the current alert when user is safe
router.post("/stop", authMiddleware, stopAlert);


// Get the currently active alert for the user
router.get("/current", authMiddleware, getCurrentAlert);

module.exports = router;
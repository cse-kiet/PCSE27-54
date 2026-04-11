const express = require("express");
const router = express.Router();

const {
  addContact,
  getContacts,
  deleteContact
} = require("../controllers/contactController");

const { authMiddleware } = require("../middleware/authMiddleware");

router.post("/add", authMiddleware, addContact);
router.get("/getContacts", authMiddleware, getContacts);
router.delete("/:id", authMiddleware, deleteContact);

module.exports = router;
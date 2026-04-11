const Contact = require("../models/ContactModel");

// Add Contact
exports.addContact = async (req, res) => {
  try {
    const { name, phone, priority } = req.body;

    const contact = await Contact.create({
      userId: req.user.userId,
      name,
      phone,
      priority
    });

    res.status(201).json({
      success: true,
      contact
    });

  } catch (error) {
    console.log(error)
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// Get All Contacts
exports.getContacts = async (req, res) => {
  try {
    const contacts = await Contact.find({
      userId: req.user.userId
    });

    res.json({
      success: true,
      contacts
    });

  } catch (error) {
    res.status(500).json({ success: false });
  }
};

// delete contact
exports.deleteContact = async (req, res) => {
  try {
    const { id } = req.params;

    await Contact.findOneAndDelete({
      _id: id,
      userId: req.user.userId
    });

    res.json({
      success: true,
      message: "Contact deleted"
    });

  } catch (error) {
    res.status(500).json({ success: false });
  }
};
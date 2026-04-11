const mongoose = require("mongoose");

const contactSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },

  name: String,

  phone: {
    type: String,
    required: true
  },

  priority: {
    type: Number,
    default: 1
  }

}, { timestamps: true });

module.exports = mongoose.model("Contact", contactSchema);
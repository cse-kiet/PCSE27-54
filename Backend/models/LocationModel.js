// models/LocationModel.js

const mongoose = require("mongoose");

const locationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },

  alertId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Alert"
  },

  lat: Number,
  lng: Number,

  createdAt: {
    type: Date,
    default: Date.now
  }

});

module.exports = mongoose.model("Location", locationSchema);
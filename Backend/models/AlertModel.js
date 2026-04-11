const mongoose = require("mongoose");

const alertSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    status: {
      type: String,
      enum: ["ACTIVE", "RESOLVED"],
      default: "ACTIVE",
    },

    stage: {
      type: Number,
      default: 1,
    },

    riskScore: {
      type: Number,
      default: 0,
    },

    locationShared: {
      type: Boolean,
      default: false,
    },

    startedAt: {
      type: Date,
      default: Date.now,
    },

    endedAt: Date,
  },
  { timestamps: true },
);

module.exports = mongoose.model("Alert", alertSchema);

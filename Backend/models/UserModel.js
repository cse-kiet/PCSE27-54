// models/User.js
const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
    name: String,
    email: {
        type: String,
        required: true,
        unique: true
    },

    password: {
        type: String,
        default: null // null for Google users
    },

    googleId: {
        type: String,
        default: null
    },

    profilePic: String,

    isMonitoring: {
        type: Boolean,
        default: false
    },

    currentStatus: {
        type: String,
        enum: ["SAFE", "SUSPICIOUS", "DANGER", "CRITICAL"],
        default: "SAFE"
    },

    currentStage: {
        type: Number,
        default: 0
    }
    
}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);
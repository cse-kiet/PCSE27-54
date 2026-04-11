const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  profilePic: {
    type: String,
    default: null,
  },
  isMonitoring: {
    type: Boolean,
    default: false,
  },
  currentStatus: {
    type: String,
    enum: ['SAFE', 'SUSPICIOUS', 'DANGER', 'CRITICAL'],
    default: 'SAFE',
  },
  currentStage: {
    type: Number,
    default: 0,
  },
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);

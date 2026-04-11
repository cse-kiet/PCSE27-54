const mongoose = require("mongoose");

const riskSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User"
    },

    text: String,
    volume: Number,
    emotion: String,

    riskScore: Number,
    stage: Number,

    createdAt: {
        type: Date,
        default: Date.now
    }

});

module.exports = mongoose.model("RiskEvent", riskSchema);
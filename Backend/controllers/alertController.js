const Alert = require("../models/AlertModel");
const Alert = require("../models/AlertModel");

exports.startAlert = async (req, res) => {
  try {
    const { riskScore, stage } = req.body;

    // Check if active alert exists
    let alert = await Alert.findOne({
      userId: req.user.userId,
      status: "ACTIVE"
    });

    if (!alert) {
      // Create new alert (first time)
      alert = await Alert.create({
        userId: req.user.userId,
        riskScore,
        stage,
        status: "ACTIVE"
      });

      return res.status(201).json({
        success: true,
        message: "Alert started",
        alert
      });
    }

    // If alert exists → update stage and risk
    // Only update if new stage is higher (important logic)
    if (stage > alert.stage) {
      alert.stage = stage;
      alert.riskScore = riskScore;

      // mark location sharing when stage increases
      if (stage >= 2) {
        alert.locationShared = true;
      }

      await alert.save();
    }

    return res.status(200).json({
      success: true,
      message: "Alert updated",
      alert
    });

  } catch (error) {
    console.error("Error handling alert:", error);

    res.status(500).json({
      success: false,
      message: "Something went wrong"
    });
  }
};


// stop the current alert
exports.stopAlert = async (req, res) => {
  try {

    // Find active alert and mark it as resolved
    const alert = await Alert.findOneAndUpdate(
      {
        userId: req.user.userId,
        status: "ACTIVE"
      },
      {
        status: "RESOLVED",
        endedAt: new Date() 
      },
      { new: true }
    );

    // If no active alert found
    if (!alert) {
      return res.status(404).json({
        success: false,
        message: "No active alert found"
      });
    }

    res.json({
      success: true,
      message: "Alert stopped successfully",
      alert
    });

  } catch (error) {
    console.error("Error stopping alert:", error);

    res.status(500).json({
      success: false,
      message: "Something went wrong"
    });
  }
};


//  Get current active alert (if any)
exports.getCurrentAlert = async (req, res) => {
  try {

    // Find active alert for this user
    const alert = await Alert.findOne({
      userId: req.user.userId,
      status: "ACTIVE"
    });

    res.json({
      success: true,
      alert // can be null if no alert is active
    });

  } catch (error) {
    console.error("Error fetching alert:", error);

    res.status(500).json({
      success: false,
      message: "Something went wrong"
    });
  }
};
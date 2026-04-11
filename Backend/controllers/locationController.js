const Location = require("../models/LocationModel");


// Save or update user location
exports.saveLocation = async (req, res) => {
  try {
    const { lat, lng, alertId } = req.body;

    // Basic validation
    if (!lat || !lng) {
      return res.status(400).json({
        success: false,
        message: "Latitude and Longitude are required"
      });
    }

    // Store location data
    const location = await Location.create({
      userId: req.user.userId,
      alertId,
      lat,
      lng
    });

    res.json({
      success: true,
      location
    });

  } catch (error) {
    console.error("Error saving location:", error);

    res.status(500).json({
      success: false,
      message: "Something went wrong"
    });
  }
};



// Get latest location of a user (for tracking link)
exports.getUserLocation = async (req, res) => {
  try {
    const { userId } = req.params;

    // Get latest location for the user
    const location = await Location.findOne({ userId })
      .sort({ createdAt: -1 });

    if (!location) {
      return res.status(404).json({
        success: false,
        message: "No location found"
      });
    }

    res.json({
      success: true,
      location
    });

  } catch (error) {
    console.error("Error fetching location:", error);

    res.status(500).json({
      success: false,
      message: "Something went wrong"
    });
  }
};
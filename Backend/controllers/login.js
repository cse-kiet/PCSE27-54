// controllers/authController.js

const User = require("../models/UserModel");

// GOOGLE LOGIN CONTROLLER
exports.googleAuth = async (req, res) => {
  try {
    const { name, email, googleId, profilePic } = req.body;

    // check if user already exists
    let user = await User.findOne({ email });

    if (!user) {
        // create new user
        user = await User.create({
        name,
        email,
        googleId,
        profilePic
        });
        
        return res.status(201).json({
        success: true,
        message: "User created successfully",
        user,
        isNewUser: true
        });
    } 
    else { 
      user.googleId = googleId || user.googleId;
      user.profilePic = profilePic || user.profilePic;
      await user.save();
    }

    return res.status(200).json({
      success: true,
      message: "Google login successful",
      user,
      isNewUser: false
    });

  } catch (error) {
    console.error("Google Auth Error:", error);

    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};
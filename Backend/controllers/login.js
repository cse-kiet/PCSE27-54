const User = require("../models/UserModel");
const jwt = require("jsonwebtoken");

// helper to generate token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: "7d" }
  );
};

// GOOGLE LOGIN CONTROLLER
exports.googleAuth = async (req, res) => {
  try {
    const { name, email, googleId, profilePic } = req.body;

    // Validation
    if (!name || !email || !googleId) {
      return res.status(400).json({
        success: false,
        message: "Invalid Google data"
      });
    }

    let user = await User.findOne({ email });

    // CREATE NEW USER
    if (!user) {
      user = await User.create({
        name,
        email,
        googleId,
        profilePic
      });

      const token = generateToken(user._id);

      return res.status(201).json({
        success: true,
        message: "User created successfully",
        user,
        token,
        isNewUser: true
      });
    }

    let updated = false;

    // link google account if not already linked
    if (!user.googleId) {
      user.googleId = googleId;
      updated = true;
    }

    // update profile pic if changed
    if (profilePic && profilePic !== user.profilePic) {
      user.profilePic = profilePic;
      updated = true;
    }

    if (updated) await user.save();

    const token = generateToken(user._id);

    return res.status(200).json({
      success: true,
      message: "Google login successful",
      user,
      token,
      isNewUser: false
    });

  } catch (error) {
    console.error("Google Auth Error:", error);

    return res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};
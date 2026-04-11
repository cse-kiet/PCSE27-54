const jwt = require("jsonwebtoken");

exports.authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: "No token provided"
      });
    }

    // Extract token from "Bearer TOKEN"
    const token = authHeader.startsWith("Bearer ")
      ? authHeader.split(" ")[1]
      : authHeader;

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || "secret_key"
    );

    req.user = decoded; // { userId }

    next();

  } 
  catch (error) {
    console.error("Auth Error:", error);

    return res.status(401).json({
      success: false,
      message: "Invalid token"
    });
  }
};
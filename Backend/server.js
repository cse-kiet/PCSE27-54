require("dotenv").config();
const express = require("express");
const connectDB = require("./config/databse");

const app = express();
const PORT = process.env.PORT || 3000;

// Connect to DB
connectDb();

// Middleware
app.use(express.json());

const userRoutes = require("./routes/userRoute");
app.use("/api/auth", userRoutes);

// Routes
app.get("/", (req, res) => {
  res.json({
    message: "Server is running",
    status: "success"
  });
});

app.get("/api/data", (req, res) => {
  res.json({
    message: "Hello from backend!",
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
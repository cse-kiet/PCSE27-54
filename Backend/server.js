require("dotenv").config();
const express = require("express");
const cors = require("cors");
const connectDb = require("./config/databse");
const contactRoutes = require("./routes/contactRoute");
const userRoutes = require("./routes/userRoute");
const sosRoutes = require("./routes/sosRoute");
const threatRoutes = require("./routes/threatRoute");

const app = express();
const PORT = process.env.PORT || 3000;

// Connect to DB
connectDb();

// Middleware
app.use(express.json());
app.use(cors());

// mounting routes
app.use("/api/auth", userRoutes);
app.use("/api/contacts", contactRoutes);
app.use("/api/sos", sosRoutes);
app.use("/api/threat", threatRoutes);


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
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Make sure firewall allows port ${PORT}`);
});
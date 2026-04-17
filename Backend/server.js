require("dotenv").config();
const express = require("express");
const cors = require("cors");
const os = require("os");
const fs = require("fs");
const path = require("path");
const connectDb = require("./config/databse");
const contactRoutes = require("./routes/contactRoute");
const userRoutes = require("./routes/userRoute");
const sosRoutes = require("./routes/sosRoute");
const threatRoutes = require("./routes/threatRoute");

const app = express();
const PORT = process.env.PORT || 4000;

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

function updateFlutterApiConfig(ip) {
  const configPath = path.join(__dirname, '..', 'frontend', 'lib', 'api_config.dart');
  if (!fs.existsSync(configPath)) return;
  let content = fs.readFileSync(configPath, 'utf8');
  content = content.replace(
    /static const String baseUrl = 'http:\/\/[^']+';/,
    `static const String baseUrl = 'http://${ip}:${PORT}';`
  );
  fs.writeFileSync(configPath, content, 'utf8');
  console.log(`✅ Updated api_config.dart with IP: ${ip}:${PORT}`);
}

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
  const localIP = getLocalIP();
  updateFlutterApiConfig(localIP);
  console.log(`Server running on http://${localIP}:${PORT}`);
  console.log(`Make sure firewall allows port ${PORT}`);
});
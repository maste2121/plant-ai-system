const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { connectDB, sequelize } = require('./config/config');

// Route Imports
const userRoutes = require('./routes/userRoutes');
const diseaseRoutes = require('./routes/diseaseRoutes');
const adminAuthRoutes = require('./routes/adminAuthRoutes');

const app = express();

// 1. Global Middlewares
app.use(cors()); // Critical for Flutter and Web testing
app.use(express.json()); // Body parser for JSON
app.use(express.urlencoded({ extended: true }));

// 2. Request Logger (Terminal Debugging)
// This captures every request and displays the body to check "spelling" from Flutter
// 2. Request Logger (Terminal Debugging)
app.use((req, res, next) => {
  console.log('--- NEW REQUEST ---');
  console.log(`[${new Date().toLocaleString()}] ${req.method} ${req.originalUrl}`);

  // FIX: Added "req.body &&" to prevent crash when body is undefined
  if (req.body && Object.keys(req.body).length > 0) {
    console.log("Body received:", req.body);
  }
  next();
});

// 3. Mount Routes
app.use('/api/users', userRoutes);
app.use('/api/admin/diseases', diseaseRoutes);
app.use('/api/admin', adminAuthRoutes);

// 4. Root Endpoint
app.get('/', (req, res) => {
  res.json({
    message: "KARE AI Backend is Live",
    status: "Healthy",
    timestamp: new Date().toLocaleString()
  });
});

// 5. Global Error Handler (Keep at the bottom of middleware stack)
app.use((err, req, res, next) => {
  console.error('🔴 BACKEND CRASHED:', err.stack);
  res.status(500).send({
    success: false,
    message: 'Server Error',
    error: err.message
  });
});

// 6. Start Server & Sync Database
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Ensure MySQL connects
    await connectDB();

    // ✅ Sync models (Creates/Updates tables like 'scans' automatically)
    // Use { alter: true } in development to update tables without deleting data
    await sequelize.sync({ alter: true });
    console.log("🚀 Database tables synced.");

    // Listen on '0.0.0.0' so your Flutter app can connect via your PC's IP address
    app.listen(PORT, '0.0.0.0', () => {
      const ipAddress = process.env.IP_ADDRESS || 'localhost';
      console.log(`-----------------------------------------------`);
      console.log(`🍀 KARE AI Server running on Port: ${PORT}`);
      console.log(`📍 Network URL: http://${ipAddress}:${PORT}`);
      console.log(`-----------------------------------------------`);
    });
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1); // Exit if DB connection fails
  }
};

startServer();
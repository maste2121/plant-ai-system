// server.js
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const { connectDB } = require('./config/config'); // Import connectDB from config
const diseaseRoutes = require('./routes/diseaseRoutes');
// Load environment variables
dotenv.config();

// Connect to MySQL & Sync Models
connectDB();

const app = express();

// Middleware
app.use(express.json()); // Body parser for JSON
app.use(cors()); // Enable CORS
//

app.use('/api/admin/diseases', diseaseRoutes);

// Routes (will add later)
app.get('/', (req, res) => {
  res.send('API is running...');
});

// Import and use auth routes (will recreate this file next)
const adminAuthRoutes = require('./routes/adminAuthRoutes');
app.use('/api/admin', adminAuthRoutes);
// server/server.js
const userRoutes = require('./routes/userRoutes');

// This makes the path: /api/users/register
app.use('/api/users', userRoutes);

// Add this to see every request in the terminal
app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleString()}] ${req.method} ${req.url}`);
  console.log("Body received:", req.body); // This shows the "spelling" from Flutter
  next();
});

const PORT = process.env.PORT || 5000;

// ✅ Add '0.0.0.0' to tell Node to listen to ALL devices on the Wi-Fi
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://10.64.82.100:${PORT}`);
});


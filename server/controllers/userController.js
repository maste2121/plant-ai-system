// server/controllers/adminController.js 
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

/**
 * 🛡️ Generate JWT Token
 * Standard practice: valid for 30 days for farmer convenience
 */
const generateToken = (id) => {
  return jwt.sign(
    { id },
    process.env.JWT_SECRET || 'kare_secret_key_2024',
    { expiresIn: '30d' }
  );
};

/**
 * 📝 REGISTER USER
 * Handles: full_name, phone, location, language_pref
 */
exports.registerUser = async (req, res) => {
  try {
    const { full_name, phone, password, location, language_pref, email } = req.body;

    // 1. Check if user already exists (Phone is the primary ID)
    const userExists = await User.findOne({ where: { phone } });
    if (userExists) {
      return res.status(400).json({ message: "Phone number already registered" });
    }

    // 2. Hash password (Security standard)
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password || 'password123', salt);

    // 3. Create User in MySQL via Sequelize
    const user = await User.create({
      full_name,
      phone,
      location,
      language_pref: language_pref || 'Amharic',
      email: email || null,
      password: hashedPassword,
    });

    console.log(`✅ New User Registered: ${full_name} (${phone})`);

    // 4. Return success data matching Flutter AuthService spelling
    res.status(201).json({
      token: generateToken(user.id),
      user: {
        id: user.id,
        full_name: user.full_name,
        phone: user.phone,
        language_pref: user.language_pref,
        location: user.location
      }
    });
  } catch (error) {
    console.error("🔴 Registration Error:", error);
    res.status(500).json({ message: "Server error during registration", error: error.message });
  }
};

/**
 * 🔑 LOGIN USER
 * Validates Phone and Password
 */
/**
 * 🔑 LOGIN USER
 * Distinguished logic for User Not Found vs. Wrong Password
 */
exports.loginUser = async (req, res) => {
  try {
    const { phone, password } = req.body;

    // 1. Find user in Database
    const user = await User.findOne({ where: { phone } });

    // 🟢 NEW UPDATE: If user is not found, return 404 (Not Found)
    // This tells Flutter to suggest the registration page
    if (!user) {
      return res.status(404).json({
        message: "Account not found. Please register first.",
        amharic_message: "መለያዎ አልተገኘም። እባክዎን መጀመሪያ ይመዝገቡ።",
        suggestRegister: true
      });
    }

    // 2. Compare passwords
    const isMatch = await bcrypt.compare(password || 'password123', user.password);

    if (isMatch) {
      console.log(`🔑 User Logged In: ${user.full_name}`);

      res.json({
        token: generateToken(user.id),
        user: {
          id: user.id,
          full_name: user.full_name,
          phone: user.phone,
          language_pref: user.language_pref,
          location: user.location
        }
      });
    } else {
      // User exists, but password was wrong
      res.status(401).json({
        message: "Invalid password",
        amharic_message: "ያስገቡት የይለፍ ቃል ትክክል አይደለም።"
      });
    }
  } catch (error) {
    console.error("🔴 Login Error:", error);
    res.status(500).json({ message: "Login error", error: error.message });
  }
};

/**
 * 👤 GET USER PROFILE
 * Required for the Flutter Profile Page
 */
exports.getProfile = async (req, res) => {
  try {
    // req.user is set by the Auth Middleware (Member 2's task)
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password'] }
    });

    if (user) {
      res.json(user);
    } else {
      res.status(404).json({ message: "User not found" });
    }
  } catch (error) {
    res.status(500).json({ message: "Error fetching profile", error: error.message });
  }
};
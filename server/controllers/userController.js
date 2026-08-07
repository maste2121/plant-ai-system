const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// 🛡️ Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'kare_secret_key_2024', { expiresIn: '30d' });
};

// 📝 REGISTER USER
exports.registerUser = async (req, res) => {
  try {
    const { full_name, phone, location, language_pref, password, email } = req.body;

    // 1. Check if user already exists
    const userExists = await User.findOne({ where: { phone } });
    if (userExists) {
      return res.status(400).json({ message: "Phone number already registered" });
    }

    // 2. Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password || 'password123', salt);

    // 3. Create User in MySQL
    const user = await User.create({
      full_name,
      phone,
      location,
      language_pref,
      email: email || null,
      password: hashedPassword,
    });

    // 4. Return success data
    res.status(201).json({
      token: generateToken(user.id),
      user: {
        id: user.id,
        full_name: user.full_name,
        phone: user.phone,
        language_pref: user.language_pref,
      }
    });
  } catch (error) {
    console.error("Registration Error:", error);
    res.status(500).json({ message: "Server error during registration", error: error.message });
  }
};

// 🔑 LOGIN USER
exports.loginUser = async (req, res) => {
  try {
    const { phone, password } = req.body;
    const user = await User.findOne({ where: { phone } });

    if (user && (await bcrypt.compare(password || 'password123', user.password))) {
      res.json({
        token: generateToken(user.id),
        user: {
          id: user.id,
          full_name: user.full_name,
          phone: user.phone,
          language_pref: user.language_pref
        }
      });
    } else {
      res.status(401).json({ message: "Invalid phone or password" });
    }
  } catch (error) {
    res.status(500).json({ message: "Login error", error: error.message });
  }
};
const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');
const User = require('../models/User'); // ✅ Added User model

module.exports = async function (req, res, next) {
  let token = req.header('Authorization');

  if (token && token.startsWith('Bearer ')) {
    token = token.split(' ')[1];
  } else {
    token = req.header('x-auth-token');
  }

  if (!token) {
    return res.status(401).json({ success: false, message: 'No token, authorization denied' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret_123');

    // ✅ CHECK FOR ADMIN
    if (decoded.admin) {
      const admin = await Admin.findByPk(decoded.admin.id);
      if (admin) {
        req.admin = {
          id: admin.id,
          email: admin.email,
          role: admin.role
        };
        return next();
      }
    }

    // ✅ CHECK FOR USER (Added this block to fix your null user_id issue)
    // Supports both { user: { id } } and { id } formats
    const userId = decoded.user ? decoded.user.id : decoded.id;
    if (userId) {
      const user = await User.findByPk(userId);
      if (user) {
        req.user = {
          id: user.id,
          phone: user.phone
        };
        return next();
      }
    }

    // If neither Admin nor User is found
    return res.status(401).json({ success: false, msg: 'Token is valid but record not found' });

  } catch (err) {
    console.error("Middleware authorization error:", err.message);
    res.status(401).json({ success: false, message: 'Token signature is not valid or expired' });
  }
};
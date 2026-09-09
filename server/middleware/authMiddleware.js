// server/middleware/authMiddleware.js
const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');
const User = require('../models/User'); // ✅ Added User model

module.exports = async function (req, res, next) {
  // 1. Extract token from standard 'Authorization' or fallback 'x-auth-token' header
  let token = req.header('Authorization');

  if (token && token.startsWith('Bearer ')) {
    // Split "Bearer <token_string>" to get just the token payload string
    token = token.split(' ')[1];
  } else {
    // Fallback to checking the direct custom header if Bearer isn't present
    token = req.header('x-auth-token');
  }

  // 2. Terminate request if no token credentials are passed
  if (!token) {
    return res.status(401).json({ success: false, msg: 'No token, authorization denied' });
  }

  // 3. Cryptographic Token Verification Loop
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

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
    res.status(401).json({ success: false, msg: 'Token signature is not valid or expired' });
  }
};
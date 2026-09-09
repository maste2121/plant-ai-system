const express = require('express');
const router = express.Router();
const multer = require('multer'); // ✅ Added for Image Handling
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');
const { registerUser, loginUser, getProfile } = require('../controllers/userController');
const { detectDisease, getUserHistory } = require('../controllers/diseaseController');
const diseaseController = require('../controllers/diseaseController'); // ✅ Added for AI logic

// ⚙️ Multer Configuration: Store image in memory for fast AI processing
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// ---------------------------------------------------------
// 🟢 PUBLIC ROUTES (For Flutter App)
// ---------------------------------------------------------

// Register Path: POST /api/users/register
router.post('/register', registerUser);

// Login Path: POST /api/users/login
router.post('/login', loginUser);

// 🔍 AI Detection Path: POST /api/users/predict
// Added authMiddleware here to fix the user_id null issue
router.post('/predict', authMiddleware, upload.single('image'), detectDisease);

// ---------------------------------------------------------
// 🔐 PROTECTED ROUTES (Requires JWT Token)
// ---------------------------------------------------------
router.get('/history', authMiddleware, getUserHistory);
router.get('/tips', authMiddleware, diseaseController.getFarmingTips);
router.get('/notifications', authMiddleware, diseaseController.getNotifications);
router.put('/notifications/:id/read', authMiddleware, diseaseController.markAsRead);
router.get('/assistant/history', authMiddleware, diseaseController.getAssistantHistory);
router.post('/assistant/save', authMiddleware, diseaseController.saveAssistantChat);
// Get current logged-in user profile: GET /api/users/profile
router.get('/profile', authMiddleware, getProfile);

// Get all farmers for monitoring (SRD 3.4 User Management)
router.get('/', authMiddleware, async (req, res) => {
  try {
    const users = await User.findAll({
      attributes: { exclude: ['password'] }
    });
    res.json(users);
  } catch (err) {
    res.status(500).json({ msg: 'Server error fetching users' });
  }
});

// Update user status (SRD 3.4 Block/Activate)
router.put('/:id/status', authMiddleware, async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ msg: 'User not found' });

    user.status = req.body.status;
    await user.save();
    res.json({ msg: `User status updated to ${user.status}`, status: user.status });
  } catch (err) {
    res.status(500).json({ msg: 'Update failed' });
  }
});

module.exports = router;
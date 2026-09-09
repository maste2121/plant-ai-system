const Scan = require('../models/Scan');
const Disease = require('../models/Disease');
const Crop = require('../models/Crop');
const axios = require('axios');
const FormData = require('form-data');
const { Op } = require('sequelize');

// @desc    Analyze image using Python AI and save result to Scan history
// @route   POST /api/users/predict
exports.detectDisease = async (req, res) => {
  try {
    // 1. Validate User (Must be logged in to save user_id)
    if (!req.user || !req.user.id) {
      console.log("🔴 Auth Error: No user found in request");
      return res.status(401).json({ message: "Unauthorized: Please log in." });
    }

    // 2. Check if Multer caught the image
    if (!req.file) {
      return res.status(400).json({ message: "No image uploaded" });
    }

    // 3. Prepare FormData for Python ML Service
    const form = new FormData();
    form.append('image', req.file.buffer, {
      filename: req.file.originalname,
      contentType: req.file.mimetype,
    });

    // 4. 🚀 Call Python ML Service (Port 5000)
    const pythonResponse = await axios.post('http://127.0.0.1:5000/predict', form, {
      headers: { ...form.getHeaders() }
    });

    const aiData = pythonResponse.data;
    const aiName = aiData.disease_en.trim();

    // 5. 🔍 Find the Disease record AND the associated Crop Name
    // FIX: Using wildcards (%) around the AI name to match long DB strings
    const foundDisease = await Disease.findOne({
      where: {
        disease_name: { [Op.like]: `%${aiName}%` }
      },
      include: [{ model: Crop, attributes: ['crop_name'] }]
    });

    // Extract values safely to prevent NULLs
    const diseaseId = foundDisease ? foundDisease.id : null;
    const cropId = req.body.crop_id || (foundDisease ? foundDisease.crop_id : null);
    const cropName = foundDisease && foundDisease.Crop ? foundDisease.Crop.crop_name : "Unknown Crop";

    if (foundDisease) {
      console.log(`✅ DB Match Found: ${aiName} maps to ID ${diseaseId} (Crop: ${cropName})`);
    } else {
      console.log(`⚠️ No DB Match for: "${aiName}". Saving text result only.`);
    }

    // 6. ✅ Record result in Database (Populates user_id, crop_id, and disease_id)
    const newScan = await Scan.create({
      user_id: req.user.id,
      crop_id: cropId,
      ai_predicted_disease_id: diseaseId,
      disease_en: aiData.disease_en,
      disease_am: aiData.disease_am,
      confidence_level: aiData.confidence,
      status: aiData.disease_en.toLowerCase().includes('healthy') ? "Healthy" : "Disease",
      image_url: "captured_leaf.jpg",
      lat: req.body.lat || "9.03",
      lng: req.body.lng || "38.74",
      raw_ai_result: JSON.stringify(aiData)
    });

    // 7. Return AI result + the Database IDs to Flutter
    res.json({
      ...aiData,
      db_id: newScan.id,
      user_id: newScan.user_id,
      crop_id: newScan.crop_id,
      crop_name: cropName,
      disease_id: newScan.ai_predicted_disease_id,
      status: newScan.status
    });

  } catch (error) {
    console.error("🔴 Detection Error:", error.message);
    res.status(500).json({ message: "AI Service error", error: error.message });
  }
};

// @desc    Fetch Scan History for the specific logged-in User
// @route   GET /api/users/history
// @desc    Fetch Scan History for the specific logged-in User
// @route   GET /api/users/history
exports.getUserHistory = async (req, res) => {
  try {
    console.log(`📜 Fetching history for User ID: ${req.user.id}`);

    const history = await Scan.findAll({
      where: { user_id: req.user.id },
      order: [['created_at', 'DESC']],
      include: [
        {
          model: Crop,
          attributes: ['crop_name']
        },
        {
          model: Disease,
          // Removed disease_am from here to prevent the crash if it's missing in DB
          attributes: ['disease_name', 'treatment_organic', 'symptoms', 'description']
        }
      ]
    });

    console.log(`✅ Found ${history.length} scans for this user.`);
    res.json(history);
  } catch (error) {
    console.error("🔴 History Fetch Error:", error.message);
    res.status(500).json({
      success: false,
      message: "Error fetching history",
      error: error.message
    });
  }
};

// @desc    Get details for a single specific scan
// @route   GET /api/users/history/:id
exports.getScanById = async (req, res) => {
  try {
    const scan = await Scan.findOne({
      where: { id: req.params.id, user_id: req.user.id },
      include: [
        { model: Disease },
        { model: Crop }
      ]
    });
    if (!scan) return res.status(404).json({ message: "Scan not found" });
    res.json(scan);
  } catch (error) {
    res.status(500).json({ message: "Error fetching scan details" });
  }
};

// @desc    Delete a scan from history
// @route   DELETE /api/users/history/:id
exports.deleteScan = async (req, res) => {
  try {
    const result = await Scan.destroy({
      where: { id: req.params.id, user_id: req.user.id }
    });
    if (!result) return res.status(404).json({ message: "Scan not found" });
    res.json({ success: true, message: "Scan deleted from history" });
  } catch (error) {
    res.status(500).json({ message: "Delete failed" });
  }
};

// @desc    Add new plant disease pathology entry (Admin)
// @route   POST /api/admin/diseases
exports.addDisease = async (req, res) => {
  try {
    const {
      disease_name,
      crop_id,
      status,
      description,
      symptoms,
      causes,
      treatment_organic,
      treatment_chemical,
      prevention_tips,
      image_url
    } = req.body;

    if (!disease_name || !crop_id) {
      return res.status(400).json({ success: false, message: 'Please provide disease name and target crop ID' });
    }

    const disease = await Disease.create({
      disease_name, crop_id, status: status || 'Active', 
      display_name_en, display_name_am,
      description_en, description_am, 
      symptoms_en, symptoms_am, 
      causes_en, causes_am, 
      treatment_organic_en, treatment_organic_am, 
      treatment_chemical_en, treatment_chemical_am, 
      prevention_tips_en, prevention_tips_am, 
      image_url
    });

    const completedRecord = await Disease.findByPk(disease.id, {
      include: [{ model: Crop, attributes: ['crop_name'] }]
    });

    res.status(201).json({ success: true, data: completedRecord });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server Error', error: err.message });
  }
};

// @desc    Get all diseases with Crop relations (Catalog)
// @route   GET /api/admin/diseases
exports.getDiseases = async (req, res) => {
  try {
    const diseases = await Disease.findAll({
      order: [['id', 'DESC']],
      include: [{ model: Crop, attributes: ['crop_name'] }]
    });

    res.status(200).json({ success: true, data: diseases });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server Error', error: err.message });
  }
};

// server/controllers/diseaseController.js
const { sequelize } = require('../config/config');

exports.getFarmingTips = async (req, res) => {
  try {
    const [tips] = await sequelize.query("SELECT * FROM farming_tips ORDER BY id DESC");
    res.json(tips);
  } catch (error) {
    res.status(500).json({ message: "Error fetching tips" });
  }
};

// Fetch notifications for the logged-in user + system-wide alerts
exports.getNotifications = async (req, res) => {
  try {
    const [rows] = await sequelize.query(
      `SELECT * FROM notifications 
       WHERE user_id = :userId OR user_id IS NULL 
       ORDER BY created_at DESC`,
      { replacements: { userId: req.user.id } }
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: "Error fetching notifications" });
  }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
  try {
    await sequelize.query(
      "UPDATE notifications SET is_read = 1 WHERE id = :id",
      { replacements: { id: req.params.id } }
    );
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ message: "Update failed" });
  }
};

// Save a new voice interaction
// ✅ Correct Save Logic
exports.saveAssistantChat = async (req, res) => {
  try {
    const { query, response } = req.body;

    // 1. Validation
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: "Unauthorized: No user ID" });
    }

    // 2. Insert into MySQL
    await sequelize.query(
      "INSERT INTO assistant_history (user_id, user_query, ai_response, created_at) VALUES (:userId, :query, :response, NOW())",
      {
        replacements: {
          userId: req.user.id,
          query: query || "",
          response: response || ""
        }
      }
    );

    console.log(`✅ Assistant Chat Saved for User: ${req.user.id}`);
    res.json({ success: true });
  } catch (error) {
    console.error("🔴 DB Save Error:", error.message);
    res.status(500).json({ message: "Error saving assistant history", error: error.message });
  }
};

// Fetch recent chats for the stories UI
exports.getAssistantHistory = async (req, res) => {
  try {
    const [rows] = await sequelize.query(
      "SELECT * FROM assistant_history WHERE user_id = :userId ORDER BY created_at DESC LIMIT 10",
      { replacements: { userId: req.user.id } }
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: "Error fetching history" });
  }
};
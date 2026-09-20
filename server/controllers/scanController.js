const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const Scan = require('../models/Scan');
const Disease = require('../models/Disease');
const Crop = require('../models/Crop');

// ✅ Use cloud ML service (override via Render env var if you ever change URLs)
const ML_SERVICE_URL =
  process.env.ML_SERVICE_URL ||
  'https://plant-ai-system-1.onrender.com/predict';

// Crop recommendation model (if it lives on a different service, set env var)
const CROP_MODEL_URL =
  process.env.CROP_MODEL_URL ||
  'https://plant-ai-system-1.onrender.com/predict';

Scan.belongsTo(Disease, { foreignKey: 'ai_predicted_disease_id' });
Scan.belongsTo(Crop, { foreignKey: 'crop_id' });

exports.getRecommendation = async (req, res) => {
  try {
    const { nitrogen, phosphorus, potassium, ph, rainfall, temperature } = req.body;
    if (!nitrogen || !phosphorus || !potassium || !ph || !rainfall || !temperature) {
      return res.status(400).json({ success: false, message: 'Missing soil parameters' });
    }

    const payload = {
      type: 'crop',
      data: [
        Number(nitrogen),
        Number(phosphorus),
        Number(potassium),
        Number(ph),
        Number(rainfall),
        Number(temperature),
      ],
    };

    const response = await axios.post(CROP_MODEL_URL, payload, {
      timeout: 120000, // ✅ 2 min — Render free-tier cold start
    });
    res.status(200).json({ success: true, recommended_crop: response.data.result });
  } catch (err) {
    console.error('Crop Recommendation Error:', err.message);
    res.status(500).json({ success: false, message: 'Crop Model Service Unavailable' });
  }
};

exports.processPlantScan = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Image file required' });
    }

    const { latitude, longitude } = req.body;

    const fileBuffer = fs.readFileSync(req.file.path);
    const formData = new FormData();
    formData.append('image', fileBuffer, {
      filename: req.file.originalname,
      contentType: req.file.mimetype,
    });

    const mlResponse = await axios.post(ML_SERVICE_URL, formData, {
      headers: { ...formData.getHeaders() },
      timeout: 120000, // ✅ 2 min — Render free-tier cold start
    });

    const mlOutput = mlResponse.data;
    if (mlOutput.error) {
      return res.status(500).json({ success: false, message: mlOutput.error });
    }

    const diseaseMapping = { 'Teff Rust': 'Teff Rust (Uromyces eragrostidis)' };
    const targetName = diseaseMapping[mlOutput.result] || mlOutput.result;

    const diseaseData = await Disease.findOne({
      where: { disease_name: targetName },
      include: [{ model: Crop, attributes: ['id', 'crop_name'] }],
    });

    const userId = req.user ? req.user.id : null;
    const resolvedCropId = diseaseData ? diseaseData.crop_id : null;

    // Save scan data to the logs database regardless of whether details exist yet
    await Scan.create({
      user_id: userId,
      crop_id: resolvedCropId,
      image_url: req.file.path,
      ai_predicted_disease_id: diseaseData ? diseaseData.id : null,
      confidence_level: mlOutput.confidence,
      raw_ai_result: mlOutput.result,
      latitude: latitude || null,
      longitude: longitude || null,
    });

    // Case 1: Disease exists in the database
    if (diseaseData) {
      return res.status(200).json({
        id: diseaseData.id,
        nameEn: diseaseData.disease_name,
        nameAm: diseaseData.disease_am || diseaseData.disease_name,
        confidence: mlOutput.confidence,
        // ✅ FIXED: real column names from models/Disease.js
        treatmentOrganicEn:
          diseaseData.treatment_organic_en ||
          'No specific organic treatment registered.',
        treatmentOrganicAm:
          diseaseData.treatment_organic_am || '',
        treatmentChemicalEn:
          diseaseData.treatment_chemical_en ||
          'No specific chemical treatment registered.',
        treatmentChemicalAm:
          diseaseData.treatment_chemical_am || '',
        preventionEn:
          diseaseData.prevention_tips_en || 'No custom prevention steps found.',
        preventionAm:
          diseaseData.prevention_tips_am || '',
      });
    }

    // Case 2: GLOBAL FALLBACK - Matches any disease missing from your database rows
    console.log(`⚠️ Database row missing for "${targetName}". Triggering safe network response.`);

    return res.status(200).json({
      id: 0,
      nameEn: targetName,
      nameAm: `${targetName} (ያልተመዘገበ)`,
      confidence: mlOutput.confidence,
      treatmentOrganicEn:
        'Keep leaves dry, separate the infected plant from others, and ensure clean cultivation tools.',
      treatmentOrganicAm:
        'ቅጠሎችን ደረቅ ያድርጉ፣ የተበከለውን ተክል ከሌሎች ለዩ፣ እና ንጹህ የእርሻ መሳሪያዎችን ይጠቀሙ።',
      treatmentChemicalEn:
        'No chemical treatment profile exists in system records. Consult local extension staff.',
      treatmentChemicalAm:
        'በስርዓቱ መዝገብ ውስጥ የኬሚካል ህክምና መገለጫ የለም። የአካባቢ ኤክስቴንሽን ሰራተኞችን ያማክሩ።',
      preventionEn:
        'Maintain proper plant spacing for healthy ventilation, and clear weed hosts around production plots.',
      preventionAm:
        'ለጤናማ አየር ዝውውር ትክክለኛ የተክል ክፍተት ይጠብቁ፣ እና በአመራረት ቦታዎች ዙሪያ አረሞችን ያጽዱ።',
    });

  } catch (err) {
    console.error('Scan Error Details:', err.response?.data || err.message);
    res.status(500).json({ success: false, message: 'Server Data Processing Error' });
  }
};

exports.getUserHistory = async (req, res) => {
  try {
    const history = await Scan.findAll({
      where: { user_id: req.user.id },
      order: [['createdAt', 'DESC']],
      attributes: [
        'id',
        'image_url',
        'raw_ai_result',
        'confidence_level',
        'scan_date',
        'createdAt',
        'latitude',
        'longitude',
      ],
      include: [
        {
          model: Disease,
          // ✅ FIXED: use real column names from models/Disease.js
          attributes: [
            'disease_name',
            'display_name_en',
            'display_name_am',
            'disease_am',
            'description_en',
            'description_am',
            'symptoms_en',
            'symptoms_am',
            'causes_en',
            'causes_am',
            'treatment_organic_en',
            'treatment_organic_am',
            'treatment_chemical_en',
            'treatment_chemical_am',
            'prevention_tips_en',
            'prevention_tips_am',
            'image_url',
          ],
        },
        {
          model: Crop,
          attributes: ['crop_name'],
        },
      ],
    });
    res.json(history);
  } catch (error) {
    console.error('History Fetch Error:', error);
    res.status(500).json({ success: false, message: 'Error fetching history' });
  }
};
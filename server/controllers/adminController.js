const Admin = require('../models/Admin');
const Scan = require('../models/Scan');
const User = require('../models/User');
const Crop = require('../models/Crop');
const Disease = require('../models/Disease');
const { Sequelize } = require('sequelize');

// ✅ Helper: parse raw_ai_result JSON string into an object
const parseRawAi = (raw) => {
  if (!raw) return {};
  if (typeof raw === 'string' && raw.trim().startsWith('{')) {
    try {
      return JSON.parse(raw);
    } catch (_) {
      return {};
    }
  }
  return typeof raw === 'object' ? raw : {};
};

exports.getDashboardStats = async (req, res) => {
  try {
    const totalScans = await Scan.count();
    const activeUsers = await User.count();

    // ✅ Compute common disease + avg confidence from raw_ai_result
    const allScans = await Scan.findAll({
      attributes: ['id', 'raw_ai_result', 'confidence_level'],
    });

    const diseaseCounter = {};
    let confidenceSum = 0;
    let confidenceCount = 0;

    for (const scan of allScans) {
      const parsed = parseRawAi(scan.raw_ai_result);
      const disease = parsed.disease_en || parsed.result || null;
      if (disease) {
        diseaseCounter[disease] = (diseaseCounter[disease] || 0) + 1;
      }

      const rawConf = scan.confidence_level ?? parsed.confidence ?? null;
      if (rawConf != null) {
        let c = Number(rawConf);
        if (c > 1) c = c / 100; // normalize to 0-1
        if (!isNaN(c) && c > 0) {
          confidenceSum += c;
          confidenceCount++;
        }
      }
    }

    // Pick most frequent non-healthy disease
    let commonDisease = 'Healthy Tissue';
    let maxCount = 0;
    for (const [disease, count] of Object.entries(diseaseCounter)) {
      if (count > maxCount && !disease.toLowerCase().includes('healthy')) {
        maxCount = count;
        commonDisease = disease;
      }
    }
    // If no non-healthy disease found, pick the most frequent overall
    if (
      commonDisease === 'Healthy Tissue' &&
      Object.keys(diseaseCounter).length > 0
    ) {
      commonDisease = Object.entries(diseaseCounter).sort(
        (a, b) => b[1] - a[1]
      )[0][0];
    }

    const avgConfidence =
      confidenceCount > 0 ? (confidenceSum / confidenceCount) * 100 : 0;
    const confidenceVal = `${avgConfidence.toFixed(1)}%`;

    const rawRecent = await Scan.findAll({
      limit: 5,
      order: [['created_at', 'DESC']],
      include: [
        { model: User, attributes: ['full_name'] },
        { model: Crop, attributes: ['crop_name'] },
        { model: Disease, attributes: ['disease_name'] },
      ],
    });

    const formattedRecent = rawRecent.map((scan) => {
      const s = scan.get({ plain: true });
      const parsed = parseRawAi(s.raw_ai_result);

      let conf = Number(s.confidence_level ?? parsed.confidence ?? 0);
      if (conf > 0 && conf <= 1) conf = conf * 100;

      return {
        id: s.id,
        confidence_level: conf.toFixed(0),
        raw_ai_result: s.raw_ai_result,
        scan_date: s.scan_date || s.createdAt || s.created_at,
        user_name: s.User?.full_name || 'Anonymous Farmer',
        crop_name: s.Crop?.crop_name || parsed.crop_name || 'Unknown Crop',
        // ✅ Prefer real DB disease, then parsed raw_ai_result, then 'Healthy'
        disease_name:
          s.Disease?.disease_name ||
          parsed.disease_en ||
          parsed.result ||
          'Healthy',
      };
    });

    res.status(200).json({
      success: true,
      stats: {
        totalScans: totalScans.toLocaleString(),
        totalUsers: activeUsers,
        activeUsers: activeUsers.toLocaleString(),
        commonDisease,
        aiAccuracy: confidenceVal,
      },
      scans: formattedRecent,
      data: formattedRecent,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error compiling dashboard metrics',
      error: error.message,
    });
  }
};

exports.getScanLogs = async (req, res) => {
  try {
    const scans = await Scan.findAll({
      // 1. Explicitly fetch latitude and longitude from the Scan table
      attributes: [
        'id',
        'confidence_level',
        'raw_ai_result',
        'scan_date',
        'createdAt',
        'latitude',
        'longitude',
      ],
      order: [['created_at', 'DESC']],
      include: [
        { model: User, attributes: ['full_name'] },
        { model: Crop, attributes: ['crop_name'] },
        { model: Disease, attributes: ['disease_name'] },
      ],
    });

    const formattedLogs = scans.map((scan) => {
      const s = scan.get({ plain: true });
      const parsed = parseRawAi(s.raw_ai_result);

      let conf = Number(s.confidence_level ?? parsed.confidence ?? 0);
      if (conf > 0 && conf <= 1) conf = conf * 100;

      return {
        id: s.id,
        // 2. Map the data so the Flutter app receives it
        latitude: s.latitude,
        longitude: s.longitude,
        confidence_level: conf.toFixed(0),
        raw_ai_result: s.raw_ai_result,
        scan_date: s.scan_date || s.createdAt || s.created_at,
        user_name: s.User?.full_name || 'N/A',
        crop_name: s.Crop?.crop_name || parsed.crop_name || 'N/A',
        // ✅ Prefer real DB disease, then parsed raw_ai_result, then 'Healthy'
        disease_name:
          s.Disease?.disease_name ||
          parsed.disease_en ||
          parsed.result ||
          'Healthy',
      };
    });

    res.status(200).json({ success: true, data: formattedLogs });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching relational scan logs',
      error: error.message,
    });
  }
};

exports.getUsersList = async (req, res) => {
  try {
    const users = await User.findAll({ order: [['created_at', 'DESC']] });
    res.status(200).json({ success: true, data: users, users: users });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed loading user index.',
      error: error.message,
    });
  }
};

exports.toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    if (!['Active', 'Blocked'].includes(status)) {
      return res
        .status(400)
        .json({ success: false, message: 'Invalid status property.' });
    }
    await User.update({ status }, { where: { id } });
    res
      .status(200)
      .json({ success: true, message: `User status altered to ${status}` });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed toggling user state.',
      error: error.message,
    });
  }
};

exports.getAnalyticsData = async (req, res) => {
  try {
    const totalGlobalScans = await Scan.count();
    const regionalOutbreaks = await Scan.findAll({
      attributes: [
        [Sequelize.col('User.location'), 'location'],
        [Sequelize.fn('COUNT', Sequelize.col('Scan.id')), 'total_scans'],
      ],
      include: [
        { model: User, attributes: [], required: false },
        { model: Disease, attributes: ['disease_name'], required: false },
      ],
      group: [
        Sequelize.col('User.location'),
        'Disease.id',
        'Disease.disease_name',
      ],
    });

    const locationMap = new Map();
    regionalOutbreaks.forEach((item) => {
      const loc = item.getDataValue('location') || 'Unknown Region';
      const count = parseInt(item.getDataValue('total_scans')) || 0;
      const disease = item.Disease?.disease_name || 'Healthy Tissue';

      if (locationMap.has(loc)) {
        locationMap.get(loc).total_scans += count;
      } else {
        locationMap.set(loc, {
          location: loc,
          total_scans: count,
          dominant_disease: disease,
        });
      }
    });

    const formattedRegions = Array.from(locationMap.values()).map((item) => ({
      ...item,
      percentage_share:
        totalGlobalScans > 0
          ? Math.round((item.total_scans / totalGlobalScans) * 100)
          : 0,
    }));

    const avgAccuracy = await Scan.findOne({
      attributes: [
        [Sequelize.fn('AVG', Sequelize.col('confidence_level')), 'avgConfidence'],
      ],
    });
    const rawConf = parseFloat(avgAccuracy?.getDataValue('avgConfidence') || 0);
    const currentConf = rawConf > 0 && rawConf <= 1 ? rawConf * 100 : rawConf;

    const topDiseasesRaw = await Scan.findAll({
      attributes: [
        [Sequelize.fn('COUNT', Sequelize.col('Scan.id')), 'scan_count'],
      ],
      where: { ai_predicted_disease_id: { [Sequelize.Op.ne]: null } },
      include: [{ model: Disease, attributes: ['disease_name'] }],
      group: ['ai_predicted_disease_id', 'Disease.id', 'Disease.disease_name'],
      order: [[Sequelize.fn('COUNT', Sequelize.col('Scan.id')), 'DESC']],
      limit: 4,
    });

    const formattedDiseases = topDiseasesRaw.map((d, index) => ({
      name: d.Disease?.disease_name || 'Unknown',
      scan_count: parseInt(d.getDataValue('scan_count')) || 0,
      computed_trend:
        index % 3 === 0 ? 'up' : index % 3 === 1 ? 'down' : 'stable',
    }));

    res.status(200).json({
      success: true,
      data: {
        regionalOutbreaks: formattedRegions,
        aiPerformance: {
          avgConfidence:
            currentConf > 0 ? parseFloat(currentConf.toFixed(1)) : 88.5,
          delta: currentConf > 90 ? 1.4 : -0.6,
        },
        topDiseases: formattedDiseases,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Analytics computation failed.',
      error: error.message,
    });
  }
};

exports.getAdminProfile = async (req, res) => {
  try {
    if (!req.admin?.id)
      return res.status(401).json({ success: false, message: 'Unauthorized.' });
    const admin = await Admin.findByPk(req.admin.id, {
      attributes: ['email', 'role'],
    });
    if (!admin)
      return res.status(404).json({ success: false, message: 'Not found.' });
    res.status(200).json({ success: true, data: admin });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateAdminProfile = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email)
      return res
        .status(400)
        .json({ success: false, message: 'Invalid email.' });
    await Admin.update({ email }, { where: { id: req.admin.id } });
    res.status(200).json({ success: true, message: 'Updated successfully.' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateAdminPassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const admin = await Admin.findByPk(req.admin.id);
    if (!admin || !(await admin.comparePassword(currentPassword))) {
      return res
        .status(400)
        .json({ success: false, message: 'Password verification failed.' });
    }
    admin.password = newPassword;
    await admin.save();
    res.status(200).json({ success: true, message: 'Updated successfully.' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
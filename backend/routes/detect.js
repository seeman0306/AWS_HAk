/**
 * AquaGuard AI — AI Detection Route
 * POST /api/detect
 */

const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const aiDetectionService = require('../services/aiDetectionService');
const db = require('../config/db');

// Setup upload storage for water incident images
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '..', 'uploads'));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'aquaguard-' + uniqueSuffix + path.extname(file.originalname || '.jpg'));
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 } // 15MB limit
});

router.post('/', upload.single('image'), async (req, res) => {
  const startTime = Date.now();
  try {
    const latitude = parseFloat(req.body.latitude) || 9.524500;
    const longitude = parseFloat(req.body.longitude) || 77.638200;
    const categoryHint = req.body.categoryHint || req.body.issueType || '';
    const waterSource = req.body.waterSource || '';

    const result = await aiDetectionService.detectIssue(req.file, latitude, longitude, {
      categoryHint,
      waterSource
    });

    if (req.file) {
      result.imageUrl = `/uploads/${req.file.filename}`;
    }

    const latency = Date.now() - startTime;
    result.latencyMs = latency;

    // Persist telemetry log in PostgreSQL
    try {
      if (db.isConnected()) {
        await db.query(
          `INSERT INTO ai_detection_logs (issue_detected, confidence, raw_response, api_endpoint, latency_ms)
           VALUES ($1, $2, $3, $4, $5)`,
          [result.issueType, result.confidence, JSON.stringify(result), result.endpointUsed, latency]
        );
      }
    } catch (dbErr) {
      // Non-blocking log failure
      console.warn('[AquaGuard AI] Telemetry log notice:', dbErr.message);
    }

    return res.status(200).json({
      success: true,
      data: result,
      latencyMs: latency
    });
  } catch (error) {
    console.error('[AquaGuard AI] Detection API error:', error);
    return res.status(500).json({
      success: false,
      error: error.message || 'Unable to process water contamination image. Please try again.'
    });
  }
});

module.exports = router;

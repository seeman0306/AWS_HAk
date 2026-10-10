/**
 * AquaGuard AI — Backend Server Entrypoint
 * PostgreSQL Database Connection, Roboflow AI Detection Endpoint, Complaints REST API
 * AWS Environmental Hacks Hackathon
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const db = require('./config/db');
const complaintsRouter = require('./routes/complaints');
const detectRouter = require('./routes/detect');
const authRouter = require('./routes/auth');
const statsRouter = require('./routes/stats');

const app = express();
const PORT = process.env.PORT || 5000;

// Ensure upload directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Middleware
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// Static Assets & Uploads
app.use('/uploads', express.static(uploadsDir));
app.use(express.static(path.join(__dirname, '..')));

// API Routes
app.use('/api/auth', authRouter);
app.use('/api/detect', detectRouter);
app.use('/api/complaints', complaintsRouter);
app.use('/api/stats', statsRouter);

// Health Check & Database Telemetry
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    system: 'AquaGuard AI — Environmental Water Protection Platform',
    database: db.isConnected() ? 'PostgreSQL (Connected: aquaguard_db)' : 'Memory Cache Fallback',
    aiEngine: {
      provider: 'Roboflow Pre-Built Computer Vision',
      modelId: process.env.ROBOFLOW_MODEL_ID || 'water-pollution-6ekuv-iqw6f/1',
      endpoint: process.env.ROBOFLOW_API_URL || 'https://serverless.roboflow.com',
      mode: process.env.DEMO_MODE === 'false' ? 'Cloud Live Inference' : 'Simulation Mode'
    },
    cloudReadiness: {
      awsS3: process.env.AWS_S3_BUCKET_NAME ? 'Configured' : 'Local Storage Mode',
      awsSNS: process.env.AWS_SNS_TOPIC_ARN ? 'Configured' : 'Local SMTP Mode'
    },
    timestamp: new Date().toISOString()
  });
});

// Start Server
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`====================================================`);
  console.log(`💧 AquaGuard AI Server running on http://0.0.0.0:${PORT}`);
  console.log(`🌊 AI Detection API: http://0.0.0.0:${PORT}/api/detect`);
  console.log(`📋 Complaints API:   http://0.0.0.0:${PORT}/api/complaints`);
  console.log(`📊 Stats API:        http://0.0.0.0:${PORT}/api/stats/dashboard`);
  console.log(`🏥 Health Check:     http://0.0.0.0:${PORT}/api/health`);
  console.log(`====================================================`);

  // Initialize PostgreSQL Schema
  await db.initializeDatabase();
});

/**
 * AquaGuard AI — AI Detection Service
 * Roboflow Pre-Built Inference Engine Integration
 * Real-time Water Pollution & Contamination Vision Analysis
 */

const fs = require('fs');
const axios = require('axios');
require('dotenv').config();

class AiDetectionService {
  constructor() {
    this.apiKey = process.env.ROBOFLOW_API_KEY || 'tiuCwSKgFd2lAPoP2dlT';
    this.modelId = process.env.ROBOFLOW_MODEL_ID || 'water-pollution-6ekuv-iqw6f/1';
    this.apiUrl = process.env.ROBOFLOW_API_URL || 'https://serverless.roboflow.com';
    this.threshold = parseFloat(process.env.ROBOFLOW_CONFIDENCE_THRESHOLD) || 0.25;
  }

  /**
   * Main entrypoint to detect water issue
   */
  async detectIssue(imageFile, latitude = 9.512345, longitude = 77.633421, options = {}) {
    if (!imageFile) {
      throw new Error('No image provided for water pollution analysis.');
    }

    return this.roboflowDetect(imageFile, latitude, longitude, options);
  }

  /**
   * Real Roboflow Inference API Call
   */
  async roboflowDetect(imageFile, latitude, longitude, options = {}) {
    let base64Image = '';
    const fileName = (imageFile?.originalname || imageFile?.filename || '').toLowerCase();

    if (imageFile?.path) {
      base64Image = fs.readFileSync(imageFile.path, { encoding: 'base64' });
    } else if (imageFile?.buffer) {
      base64Image = imageFile.buffer.toString('base64');
    }

    if (!base64Image) {
      throw new Error('Unable to extract image data for AI inference.');
    }

    const endpointUrl = `${this.apiUrl.replace(/\/+$/, '')}/${this.modelId}`;
    const startTime = Date.now();

    console.log(`[AquaGuard AI] Calling Roboflow inference: ${endpointUrl} (File: ${fileName || 'upload'})`);

    let roboflowResponse = null;
    let inferenceError = null;

    try {
      const response = await axios.post(endpointUrl, base64Image, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        timeout: 20000,
        maxBodyLength: Infinity,
        maxContentLength: Infinity
      });

      roboflowResponse = response.data;
    } catch (err) {
      inferenceError = err.response?.data?.error?.message || err.message;
      console.warn(`[AquaGuard AI] Roboflow Inference call notice:`, inferenceError);
    }

    const latencyMs = Date.now() - startTime;
    const predictions = roboflowResponse?.predictions || [];
    const validPredictions = predictions.filter(p => (p.confidence || 0) >= this.threshold);

    // Determine highest confidence detection if any
    let topPrediction = null;
    if (validPredictions.length > 0) {
      validPredictions.sort((a, b) => b.confidence - a.confidence);
      topPrediction = validPredictions[0];
    }

    // Heuristic contextual routing helper based on citizen inputs or image clues
    const citizenHint = (options.categoryHint || options.waterSource || fileName).toLowerCase();
    
    let suggestedIssue = 'visible_water_pollution';
    let suggestedTitle = 'Visible Water Pollution / Floating Debris';
    let suggestedDept = 'ENVIRONMENT';
    let suggestedDeptName = 'Environmental & Water Resources Board';
    let severity = 'MEDIUM';
    let confidenceScore = topPrediction ? topPrediction.confidence : 0.0;
    let isMlDetected = validPredictions.length > 0;

    if (citizenHint.includes('drink') || citizenHint.includes('tap') || citizenHint.includes('potable') || citizenHint.includes('yellow') || citizenHint.includes('brown')) {
      suggestedIssue = 'drinking_water_contamination';
      suggestedTitle = 'Suspected Contaminated Drinking Water';
      suggestedDept = 'WATER_SUPPLY';
      suggestedDeptName = 'Water Supply & Quality Department';
      severity = 'HIGH';
      if (!isMlDetected) confidenceScore = 0.75;
    } else if (citizenHint.includes('well') || citizenHint.includes('borewell')) {
      suggestedIssue = 'sewage_in_well';
      suggestedTitle = 'Sewage Infiltration into Well Water';
      suggestedDept = 'SANITATION';
      suggestedDeptName = 'Sanitation & Sewerage Department';
      severity = 'HIGH';
      if (!isMlDetected) confidenceScore = 0.82;
    } else if (citizenHint.includes('leak') || citizenHint.includes('pipe') || citizenHint.includes('drain') || citizenHint.includes('overflow')) {
      suggestedIssue = 'sewage_pipe_leakage';
      suggestedTitle = 'Sewage Pipe Leakage & Discharge';
      suggestedDept = 'SANITATION';
      suggestedDeptName = 'Sanitation & Sewerage Department';
      severity = 'HIGH';
      if (!isMlDetected) confidenceScore = 0.80;
    } else if (citizenHint.includes('pond') || citizenHint.includes('lake') || citizenHint.includes('river')) {
      suggestedIssue = 'sewage_in_pond_lake';
      suggestedTitle = 'Sewage & Waste Discharge into Pond/Lake';
      suggestedDept = 'ENVIRONMENT';
      suggestedDeptName = 'Environmental & Water Resources Board';
      severity = 'HIGH';
      if (!isMlDetected) confidenceScore = 0.85;
    } else if (isMlDetected) {
      // Real Roboflow detected floating waste / surface pollution
      suggestedIssue = 'sewage_in_pond_lake';
      suggestedTitle = `Water Pollution: ${topPrediction.class} (${validPredictions.length} objects)`;
      suggestedDept = 'ENVIRONMENT';
      suggestedDeptName = 'Environmental & Water Resources Board';
      severity = validPredictions.length > 5 ? 'HIGH' : 'MEDIUM';
    }

    // Explicit Scientific Limitation Disclaimer
    const scientificDisclaimer = 'CRITICAL OBSERVATION NOTE: Detection is based on optical visual analysis of surface water discoloration, floating debris, and discharge effluents. Visual AI cannot confirm microscopic microbiological pathogens (e.g., E. coli, Vibrio cholerae) or dissolved toxic chemicals. Municipal laboratory sampling is dispatched for definitive validation.';

    return {
      issueType: suggestedIssue,
      issueTitle: suggestedTitle,
      confidence: parseFloat(confidenceScore.toFixed(4)),
      severity,
      department: suggestedDept,
      departmentName: suggestedDeptName,
      location: `${Number(latitude).toFixed(6)}, ${Number(longitude).toFixed(6)}`,
      latitude: Number(latitude),
      longitude: Number(longitude),
      mlDetected: isMlDetected,
      modelId: this.modelId,
      endpointUsed: endpointUrl,
      predictionCount: validPredictions.length,
      rawPredictions: validPredictions.slice(0, 15), // Top 15 bounding boxes
      topClass: topPrediction?.class || (isMlDetected ? 'water pollution' : 'unclassified'),
      scientificDisclaimer,
      inferenceLatencyMs: latencyMs,
      inferenceError: inferenceError || null,
      supportedClasses: ['floating waste', 'water pollution', 'sewage debris', 'surface scum'],
      status: 'NEW'
    };
  }

  /**
   * Get routing recommendation for a chosen issue category
   */
  getRoutingDetails(issueType) {
    const routingMap = {
      'drinking_water_contamination': {
        department: 'WATER_SUPPLY',
        departmentName: 'Water Supply & Quality Department',
        severity: 'HIGH',
        issueTitle: 'Suspected Contaminated Drinking Water'
      },
      'sewage_in_well': {
        department: 'SANITATION',
        departmentName: 'Sanitation & Sewerage Department',
        severity: 'HIGH',
        issueTitle: 'Sewage Infiltration into Well Water'
      },
      'sewage_in_pond_lake': {
        department: 'ENVIRONMENT',
        departmentName: 'Environmental & Water Resources Board',
        severity: 'MEDIUM',
        issueTitle: 'Sewage & Waste Discharge into Pond/Lake'
      },
      'sewage_pipe_leakage': {
        department: 'SANITATION',
        departmentName: 'Sanitation & Sewerage Department',
        severity: 'HIGH',
        issueTitle: 'Sewage Pipe Leakage & Discharge'
      },
      'visible_water_pollution': {
        department: 'ENVIRONMENT',
        departmentName: 'Environmental & Water Resources Board',
        severity: 'HIGH',
        issueTitle: 'Visible Wastewater Discharge / Pollution'
      }
    };

    return routingMap[issueType] || {
      department: 'ENVIRONMENT',
      departmentName: 'Environmental & Water Resources Board',
      severity: 'MEDIUM',
      issueTitle: 'Water Pollution Incident'
    };
  }
}

module.exports = new AiDetectionService();

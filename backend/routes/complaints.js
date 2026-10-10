/**
 * AquaGuard AI — Complaints CRUD & Routing API
 * Handles Water Contamination Reporting, Department Routing, and Status Lifecycle
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const nodemailer = require('nodemailer');
require('dotenv').config();

// In-memory fallback dataset if PostgreSQL is offline
let memoryComplaints = [];

// Mail transporter (configured via SMTP settings in .env)
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.ethereal.email',
  port: parseInt(process.env.SMTP_PORT, 10) || 587,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER || 'demo@aquaguard.ai',
    pass: process.env.SMTP_PASS || 'demopassword'
  }
});

/**
 * Format database row into standard AquaGuard AI complaint object
 */
function formatComplaint(row) {
  const deptNames = {
    WATER_SUPPLY: 'Water Supply & Quality Department',
    SANITATION: 'Sanitation & Sewerage Department',
    ENVIRONMENT: 'Environmental & Water Resources Board'
  };

  const issueTitles = {
    drinking_water_contamination: 'Suspected Contaminated Drinking Water',
    sewage_in_well: 'Sewage Infiltration into Well Water',
    sewage_in_pond_lake: 'Sewage & Waste Discharge into Pond/Lake',
    sewage_pipe_leakage: 'Sewage Pipe Leakage & Discharge',
    visible_water_pollution: 'Visible Wastewater Discharge / Pollution'
  };

  return {
    id: row.id,
    userId: row.user_id,
    userName: row.user_name || 'Citizen Reporter',
    issueType: row.issue_type,
    issue: issueTitles[row.issue_type] || row.issue_title || 'Water Contamination Incident',
    issueLabel: row.issue_title,
    confidence: parseFloat(row.confidence) || 0.88,
    severity: row.severity,
    departmentCode: row.department_code,
    department: row.department_name || deptNames[row.department_code] || row.department_code,
    latitude: parseFloat(row.latitude),
    longitude: parseFloat(row.longitude),
    location: row.location_str || `${parseFloat(row.latitude).toFixed(6)}, ${parseFloat(row.longitude).toFixed(6)}`,
    address: row.address,
    status: row.status,
    imageUrl: row.image_url,
    waterSourceType: row.water_source_type || 'MUNICIPAL_SOURCE',
    suspectedContaminant: row.suspected_contaminant || 'UNSPECIFIED',
    citizenDescription: row.citizen_description || '',
    aiPredictions: row.ai_predictions || null,
    notes: row.officer_notes,
    resolutionDetails: row.resolution_details,
    date: new Date(row.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }),
    time: new Date(row.created_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    timestamp: new Date(row.created_at).getTime(),
    officer: row.officer_name || `${deptNames[row.department_code] || 'Municipal'} Officer`
  };
}

/**
 * 1. GET ALL COMPLAINTS with filters
 * Supports: ?department=WATER_SUPPLY&status=NEW&severity=HIGH&search=keyword
 */
router.get('/', async (req, res) => {
  try {
    const { department, status, severity, issueType, search } = req.query;

    if (db.isConnected()) {
      let queryText = `
        SELECT c.*, d.name as department_name, d.officer_name 
        FROM complaints c
        LEFT JOIN departments d ON c.department_code = d.code
        WHERE 1=1
      `;
      const params = [];

      if (department && department !== 'ALL') {
        params.push(department);
        queryText += ` AND c.department_code = $${params.length}`;
      }
      if (status && status !== 'ALL') {
        params.push(status);
        queryText += ` AND c.status = $${params.length}`;
      }
      if (severity && severity !== 'ALL') {
        params.push(severity);
        queryText += ` AND c.severity = $${params.length}`;
      }
      if (issueType && issueType !== 'ALL') {
        params.push(issueType);
        queryText += ` AND c.issue_type = $${params.length}`;
      }
      if (search) {
        params.push(`%${search}%`);
        queryText += ` AND (c.id ILIKE $${params.length} OR c.issue_title ILIKE $${params.length} OR c.address ILIKE $${params.length} OR c.citizen_description ILIKE $${params.length})`;
      }

      queryText += ` ORDER BY c.created_at DESC;`;

      const result = await db.query(queryText, params);
      return res.json({
        success: true,
        source: 'PostgreSQL (aquaguard_db)',
        count: result.rows.length,
        data: result.rows.map(formatComplaint)
      });
    }

    // In-memory fallback
    let filtered = [...memoryComplaints];
    if (department && department !== 'ALL') filtered = filtered.filter(c => c.department_code === department);
    if (status && status !== 'ALL') filtered = filtered.filter(c => c.status === status);
    if (severity && severity !== 'ALL') filtered = filtered.filter(c => c.severity === severity);
    if (issueType && issueType !== 'ALL') filtered = filtered.filter(c => c.issue_type === issueType);
    if (search) {
      const term = search.toLowerCase();
      filtered = filtered.filter(c => 
        c.id.toLowerCase().includes(term) || 
        (c.issue_title || '').toLowerCase().includes(term) || 
        (c.address || '').toLowerCase().includes(term)
      );
    }

    return res.json({
      success: true,
      source: 'Memory Cache',
      count: filtered.length,
      data: filtered.map(formatComplaint)
    });
  } catch (error) {
    console.error('[AquaGuard AI] Error fetching complaints:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 2. GET SINGLE COMPLAINT BY ID
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (db.isConnected()) {
      const result = await db.query(`
        SELECT c.*, d.name as department_name, d.officer_name, d.officer_email
        FROM complaints c
        LEFT JOIN departments d ON c.department_code = d.code
        WHERE c.id = $1
      `, [id]);

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Complaint not found.' });
      }

      return res.json({
        success: true,
        data: formatComplaint(result.rows[0])
      });
    }

    const item = memoryComplaints.find(c => c.id === id);
    if (!item) return res.status(404).json({ success: false, error: 'Complaint not found.' });
    return res.json({ success: true, data: formatComplaint(item) });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 3. CREATE NEW WATER POLLUTION COMPLAINT
 */
router.post('/', async (req, res) => {
  try {
    const body = req.body;

    // Generate unique AquaGuard complaint ID (e.g. AQG-4982A)
    const randomSuffix = Math.random().toString(36).substring(2, 6).toUpperCase() + String.fromCharCode(65 + Math.floor(Math.random() * 26));
    const generatedId = body.id || `AQG-${randomSuffix}`;

    // Smart routing verification
    let assignedDept = body.departmentCode;
    const issueType = body.issueType || 'drinking_water_contamination';

    if (!assignedDept) {
      if (issueType === 'drinking_water_contamination') {
        assignedDept = 'WATER_SUPPLY';
      } else if (issueType === 'sewage_in_well' || issueType === 'sewage_pipe_leakage') {
        assignedDept = 'SANITATION';
      } else {
        assignedDept = 'ENVIRONMENT';
      }
    }

    const newRecord = {
      id: generatedId,
      user_id: body.userId || 'usr_citizen_01',
      user_name: body.userName || 'Citizen Reporter',
      issue_type: issueType,
      issue_title: body.issueLabel || body.issue || 'Suspected Water Contamination',
      confidence: parseFloat(body.confidence) || 0.88,
      severity: body.severity || (issueType === 'drinking_water_contamination' || issueType === 'sewage_in_well' ? 'HIGH' : 'MEDIUM'),
      department_code: assignedDept,
      latitude: parseFloat(body.latitude) || 9.524500,
      longitude: parseFloat(body.longitude) || 77.638200,
      location_str: body.location || `${parseFloat(body.latitude || 9.524500).toFixed(6)}, ${parseFloat(body.longitude || 77.638200).toFixed(6)}`,
      address: body.address || 'GPS Tagged Water Source',
      status: 'NEW',
      image_url: body.imageUrl || 'assets/sample_drinking_water.jpg',
      water_source_type: body.waterSourceType || 'DRINKING_TAP',
      suspected_contaminant: body.suspectedContaminant || 'TURBIDITY_ODOR',
      citizen_description: body.citizenDescription || body.description || 'Citizen submitted water contamination report via AquaGuard AI.',
      ai_predictions: body.aiPredictions ? JSON.stringify(body.aiPredictions) : null,
      officer_notes: body.notes || 'Registered in municipal water monitoring dispatch queue.',
      resolution_details: null,
      created_at: new Date().toISOString()
    };

    if (db.isConnected()) {
      const insertSql = `
        INSERT INTO complaints (
          id, user_id, user_name, issue_type, issue_title, confidence, severity,
          department_code, latitude, longitude, location_str, address, status,
          image_url, water_source_type, suspected_contaminant, citizen_description,
          ai_predictions, officer_notes, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
        RETURNING *;
      `;
      const values = [
        newRecord.id, newRecord.user_id, newRecord.user_name, newRecord.issue_type, newRecord.issue_title,
        newRecord.confidence, newRecord.severity, newRecord.department_code, newRecord.latitude, newRecord.longitude,
        newRecord.location_str, newRecord.address, newRecord.status, newRecord.image_url,
        newRecord.water_source_type, newRecord.suspected_contaminant, newRecord.citizen_description,
        newRecord.ai_predictions, newRecord.officer_notes, newRecord.created_at
      ];

      const result = await db.query(insertSql, values);
      return res.status(201).json({
        success: true,
        message: 'Water contamination complaint saved in PostgreSQL database.',
        data: formatComplaint(result.rows[0])
      });
    }

    // Memory fallback
    memoryComplaints.unshift(newRecord);
    return res.status(201).json({
      success: true,
      message: 'Water contamination complaint saved in memory.',
      data: formatComplaint(newRecord)
    });
  } catch (error) {
    console.error('[AquaGuard AI] Error creating complaint:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 4. UPDATE COMPLAINT STATUS (By Department Officer or Admin)
 * Supports: ASSIGNED, IN PROGRESS, RESOLVED, REJECTED
 */
router.patch('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes, resolutionDetails, officerRole, departmentCode } = req.body;

    const validStatuses = ['NEW', 'ASSIGNED', 'IN PROGRESS', 'RESOLVED', 'REJECTED'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: `Invalid status. Allowed: ${validStatuses.join(', ')}`
      });
    }

    let updatedComplaint = null;

    if (db.isConnected()) {
      // Check current record and department authorization
      const checkRes = await db.query('SELECT * FROM complaints WHERE id = $1', [id]);
      if (checkRes.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Complaint not found.' });
      }

      const current = checkRes.rows[0];

      // Enforce department-level authorization if officerRole is provided
      if (officerRole && officerRole !== 'OVERALL_ADMIN') {
        const expectedDept = {
          WATER_OFFICER: 'WATER_SUPPLY',
          SANITATION_OFFICER: 'SANITATION',
          ENVIRONMENT_OFFICER: 'ENVIRONMENT'
        }[officerRole];

        if (expectedDept && current.department_code !== expectedDept) {
          return res.status(403).json({
            success: false,
            error: `Access Denied: Officer from ${officerRole} cannot modify complaints routed to ${current.department_code}.`
          });
        }
      }

      const updateSql = `
        UPDATE complaints 
        SET status = $1, 
            officer_notes = COALESCE($2, officer_notes),
            resolution_details = COALESCE($3, resolution_details),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $4
        RETURNING *;
      `;
      const result = await db.query(updateSql, [status, notes || null, resolutionDetails || null, id]);
      updatedComplaint = result.rows[0];
    } else {
      const item = memoryComplaints.find(c => c.id === id);
      if (!item) return res.status(404).json({ success: false, error: 'Complaint not found.' });
      item.status = status;
      if (notes) item.officer_notes = notes;
      if (resolutionDetails) item.resolution_details = resolutionDetails;
      updatedComplaint = item;
    }

    // Optional Notification Dispatch (AWS SNS / SMTP)
    if (status === 'RESOLVED' && updatedComplaint.user_id && db.isConnected()) {
      try {
        const userRes = await db.query('SELECT email, full_name FROM users WHERE id = $1', [updatedComplaint.user_id]);
        if (userRes.rows.length > 0) {
          const user = userRes.rows[0];
          console.log(`[AquaGuard AI Notification] Dispatching resolution alert to ${user.email} for ${id}`);
          transporter.sendMail({
            from: '"AquaGuard AI Alerts" <noreply@aquaguard.ai>',
            to: user.email,
            subject: `AquaGuard AI: Your Water Quality Complaint ${id} is RESOLVED`,
            html: `
              <div style="font-family: Arial, sans-serif; padding: 24px; background: #f0f9ff; border-radius: 12px;">
                <h2 style="color: #0369a1; margin-top:0;">AquaGuard AI — Resolution Report</h2>
                <p>Hello <strong>${user.full_name}</strong>,</p>
                <p>Your reported water contamination incident (<strong>${updatedComplaint.issue_title}</strong>) at <strong>${updatedComplaint.location_str}</strong> has been resolved by the municipal department.</p>
                <div style="background: white; padding: 16px; border-left: 4px solid #0284c7; border-radius: 6px; margin: 18px 0;">
                  <strong>Action Taken / Resolution:</strong><br/>
                  ${notes || resolutionDetails || 'Water pipeline flushed and chlorine levels verified.'}
                </div>
                <p style="color: #64748b; font-size: 13px;">Thank you for safeguarding public health through AquaGuard AI.</p>
              </div>
            `
          }).catch(() => {});
        }
      } catch (err) {
        // Non-blocking
      }
    }

    return res.json({
      success: true,
      message: `Complaint ${id} status updated to ${status}.`,
      data: formatComplaint(updatedComplaint)
    });
  } catch (error) {
    console.error('[AquaGuard AI] Error updating status:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 5. REASSIGN DEPARTMENT (By Admin)
 */
router.patch('/:id/department', async (req, res) => {
  try {
    const { id } = req.params;
    const { departmentCode, notes } = req.body;

    const validDepts = ['WATER_SUPPLY', 'SANITATION', 'ENVIRONMENT'];
    if (!validDepts.includes(departmentCode)) {
      return res.status(400).json({
        success: false,
        error: `Invalid department code. Allowed: ${validDepts.join(', ')}`
      });
    }

    if (db.isConnected()) {
      const updateSql = `
        UPDATE complaints 
        SET department_code = $1,
            officer_notes = COALESCE($2, officer_notes),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $3
        RETURNING *;
      `;
      const result = await db.query(updateSql, [departmentCode, notes || `Reassigned to ${departmentCode} by Administrator.`, id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Complaint not found.' });
      }
      return res.json({
        success: true,
        message: `Complaint ${id} reassigned to ${departmentCode}.`,
        data: formatComplaint(result.rows[0])
      });
    }

    const item = memoryComplaints.find(c => c.id === id);
    if (!item) return res.status(404).json({ success: false, error: 'Complaint not found.' });
    item.department_code = departmentCode;
    if (notes) item.officer_notes = notes;
    return res.json({
      success: true,
      message: `Complaint ${id} reassigned in memory.`,
      data: formatComplaint(item)
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;

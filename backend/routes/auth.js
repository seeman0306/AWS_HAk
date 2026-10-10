/**
 * AquaGuard AI — Authentication Endpoint
 * POST /api/auth/login
 * POST /api/auth/signup
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, error: 'Email is required.' });
    }

    const cleanEmail = email.toLowerCase().trim();

    if (db.isConnected()) {
      const result = await db.query('SELECT * FROM users WHERE LOWER(email) = $1', [cleanEmail]);
      if (result.rows.length > 0) {
        const user = result.rows[0];
        return res.json({
          success: true,
          user: {
            id: user.id,
            email: user.email,
            fullName: user.full_name,
            role: user.role,
            departmentCode: user.department_code
          }
        });
      }
    }

    // Role derivation fallback for demo logins
    let role = 'CITIZEN';
    let dept = null;
    let name = 'Citizen User';
    let id = 'usr_citizen_01';

    if (cleanEmail.includes('water') || cleanEmail.includes('road')) {
      role = 'WATER_OFFICER';
      dept = 'WATER_SUPPLY';
      name = 'Dr. Rajesh Verma (Water Supply)';
      id = 'usr_officer_water';
    } else if (cleanEmail.includes('sanitation') || cleanEmail.includes('sewage') || cleanEmail.includes('street')) {
      role = 'SANITATION_OFFICER';
      dept = 'SANITATION';
      name = 'Eng. Meera Nair (Sanitation)';
      id = 'usr_officer_sanitation';
    } else if (cleanEmail.includes('environment') || cleanEmail.includes('lake') || cleanEmail.includes('traffic')) {
      role = 'ENVIRONMENT_OFFICER';
      dept = 'ENVIRONMENT';
      name = 'Officer Ananya Sen (Environment)';
      id = 'usr_officer_environment';
    } else if (cleanEmail.includes('admin')) {
      role = 'OVERALL_ADMIN';
      dept = null;
      name = 'Municipal Commissioner (Overall Admin)';
      id = 'usr_admin_01';
    }

    return res.json({
      success: true,
      user: {
        id,
        email: cleanEmail,
        fullName: name,
        role,
        departmentCode: dept
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/signup', async (req, res) => {
  try {
    const { fullName, email, password, phone } = req.body;
    if (!fullName || !email || !password) {
      return res.status(400).json({ success: false, error: 'Name, email, and password are required.' });
    }

    const cleanEmail = email.toLowerCase().trim();

    if (db.isConnected()) {
      const existing = await db.query('SELECT * FROM users WHERE LOWER(email) = $1', [cleanEmail]);
      if (existing.rows.length > 0) {
        return res.status(400).json({ success: false, error: 'Email is already registered. Please sign in.' });
      }

      const userId = 'usr_cit_' + Math.random().toString(36).substring(2, 7);
      await db.query(
        'INSERT INTO users (id, email, password_hash, full_name, role, phone) VALUES ($1, $2, $3, $4, $5, $6)',
        [userId, cleanEmail, password, fullName, 'CITIZEN', phone || null]
      );

      return res.json({
        success: true,
        user: {
          id: userId,
          email: cleanEmail,
          fullName: fullName,
          role: 'CITIZEN',
          departmentCode: null
        }
      });
    }

    const fallbackId = 'usr_cit_' + Math.random().toString(36).substring(2, 7);
    return res.json({
      success: true,
      user: {
        id: fallbackId,
        email: cleanEmail,
        fullName: fullName,
        role: 'CITIZEN',
        departmentCode: null
      }
    });
  } catch (err) {
    console.error('[AquaGuard AI] Signup error:', err);
    return res.status(500).json({ success: false, error: 'Internal server error during registration.' });
  }
});

module.exports = router;

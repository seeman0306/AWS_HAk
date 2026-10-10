/**
 * AquaGuard AI — Dashboard Statistics API
 * GET /api/stats/dashboard
 */

const express = require('express');
const router = express.Router();
const db = require('../config/db');

router.get('/dashboard', async (req, res) => {
  try {
    if (db.isConnected()) {
      const totalResult = await db.query('SELECT COUNT(*) FROM complaints');
      const deptResult = await db.query('SELECT department_code, COUNT(*) as count FROM complaints GROUP BY department_code');
      const statusResult = await db.query('SELECT status, COUNT(*) as count FROM complaints GROUP BY status');
      const severityResult = await db.query('SELECT severity, COUNT(*) as count FROM complaints GROUP BY severity');
      const issueResult = await db.query('SELECT issue_type, COUNT(*) as count FROM complaints GROUP BY issue_type');
      const highPriorityResult = await db.query("SELECT COUNT(*) FROM complaints WHERE severity = 'HIGH' AND status != 'RESOLVED'");

      const byDept = {};
      deptResult.rows.forEach(r => { byDept[r.department_code] = parseInt(r.count, 10); });

      const byStatus = {};
      statusResult.rows.forEach(r => { byStatus[r.status] = parseInt(r.count, 10); });

      const bySeverity = {};
      severityResult.rows.forEach(r => { bySeverity[r.severity] = parseInt(r.count, 10); });

      const byIssue = {};
      issueResult.rows.forEach(r => { byIssue[r.issue_type] = parseInt(r.count, 10); });

      const totalComplaints = parseInt(totalResult.rows[0].count, 10);
      const openUnresolved = (byStatus['NEW'] || 0) + (byStatus['ASSIGNED'] || 0) + (byStatus['IN PROGRESS'] || 0);

      return res.json({
        success: true,
        stats: {
          totalComplaints,
          openUnresolved,
          highPriorityPending: parseInt(highPriorityResult.rows[0].count, 10),
          waterSupplyIssues: byDept['WATER_SUPPLY'] || 0,
          sanitationIssues: byDept['SANITATION'] || 0,
          environmentIssues: byDept['ENVIRONMENT'] || 0,
          newCount: byStatus['NEW'] || 0,
          assignedCount: byStatus['ASSIGNED'] || 0,
          inProgressCount: byStatus['IN PROGRESS'] || 0,
          resolvedCount: byStatus['RESOLVED'] || 0,
          rejectedCount: byStatus['REJECTED'] || 0,
          byDept,
          byStatus,
          bySeverity,
          byIssue
        }
      });
    }

    // Default stats fallback
    res.json({
      success: true,
      stats: {
        totalComplaints: 5,
        openUnresolved: 4,
        highPriorityPending: 3,
        waterSupplyIssues: 1,
        sanitationIssues: 2,
        environmentIssues: 2,
        newCount: 2,
        assignedCount: 1,
        inProgressCount: 1,
        resolvedCount: 1,
        rejectedCount: 0,
        byDept: { WATER_SUPPLY: 1, SANITATION: 2, ENVIRONMENT: 2 },
        byStatus: { NEW: 2, ASSIGNED: 1, 'IN PROGRESS': 1, RESOLVED: 1 },
        bySeverity: { HIGH: 4, MEDIUM: 1, LOW: 0 }
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;

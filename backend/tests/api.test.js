/**
 * AquaGuard AI — End-to-End Test Suite
 * Tests Roboflow AI inference, PostgreSQL persistence, and complaints routing
 */

const axios = require('axios');
const fs = require('fs');
const path = require('path');
const FormData = require('form-data');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:5000';

async function runTests() {
  console.log('========================================================');
  console.log('🧪 AquaGuard AI — End-to-End System & API Verification');
  console.log(`🌐 Testing against base URL: ${BASE_URL}`);
  console.log('========================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, name) {
    if (condition) {
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${name}`);
      failed++;
    }
  }

  // 1. Health Check
  try {
    const res = await axios.get(`${BASE_URL}/api/health`);
    assert(res.status === 200 && res.data.status === 'healthy', 'GET /api/health returns healthy system status');
    assert(res.data.aiEngine.modelId.includes('water-pollution'), 'AI Engine references Roboflow water-pollution model');
    console.log(`     Database Status: ${res.data.database}`);
  } catch (e) {
    assert(false, `GET /api/health failed: ${e.message}`);
  }

  // 2. Authentication
  try {
    const citizenLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'citizen@aquaguard.ai',
      password: '123'
    });
    assert(citizenLogin.data.success && citizenLogin.data.user.role === 'CITIZEN', 'Citizen authentication successful');

    const waterOfficerLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'water@aquaguard.ai',
      password: '123'
    });
    assert(waterOfficerLogin.data.success && waterOfficerLogin.data.user.departmentCode === 'WATER_SUPPLY', 'Water Supply Officer authentication routed correctly');

    const adminLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'admin@aquaguard.ai',
      password: '123'
    });
    assert(adminLogin.data.success && adminLogin.data.user.role === 'OVERALL_ADMIN', 'Overall Administrator authentication validated');
  } catch (e) {
    assert(false, `Authentication endpoints failed: ${e.message}`);
  }

  // 3. AI Detection with Roboflow
  let detectedImageUrl = null;
  let detectedPayload = null;
  try {
    const samplePath = path.join(__dirname, '..', '..', 'assets', 'sample_pond_pollution.jpg');
    if (fs.existsSync(samplePath)) {
      const form = new FormData();
      form.append('image', fs.createReadStream(samplePath));
      form.append('latitude', '9.531200');
      form.append('longitude', '77.645100');
      form.append('categoryHint', 'sewage_in_pond_lake');

      const res = await axios.post(`${BASE_URL}/api/detect`, form, {
        headers: form.getHeaders(),
        timeout: 25000
      });

      assert(res.status === 200 && res.data.success === true, 'POST /api/detect executes Roboflow AI inference');
      assert(res.data.data.department === 'ENVIRONMENT', 'Pond sewage contamination correctly mapped to ENVIRONMENT board');
      assert(Array.isArray(res.data.data.rawPredictions), 'Returns real predictions array from Roboflow model');
      assert(!!res.data.data.scientificDisclaimer, 'Provides mandatory scientific limitation disclaimer');

      detectedImageUrl = res.data.data.imageUrl;
      detectedPayload = res.data.data;
      console.log(`     Inference Latency: ${res.data.latencyMs}ms | Detected Objects: ${res.data.data.predictionCount}`);
    } else {
      console.warn('     Skipping image upload test: sample image not found at', samplePath);
    }
  } catch (e) {
    assert(false, `POST /api/detect failed: ${e.response?.data?.error || e.message}`);
  }

  // 4. Create Complaint (Persist in PostgreSQL)
  let createdComplaintId = null;
  try {
    const newComplaint = {
      userId: 'usr_citizen_01',
      userName: 'Kishore Sundar',
      issueType: 'sewage_in_well',
      issueLabel: 'Sewage Infiltration into Well Water',
      confidence: 0.9410,
      severity: 'HIGH',
      departmentCode: 'SANITATION',
      latitude: 9.516800,
      longitude: 77.629400,
      location: '9.516800, 77.629400',
      address: 'Opposite Sivan Temple Well, West Bazaar Ward',
      waterSourceType: 'OPEN_WELL',
      suspectedContaminant: 'SEWAGE',
      citizenDescription: 'E2E Automated Test: Sewage water overflowing into open community drinking well.',
      imageUrl: detectedImageUrl || 'assets/sample_well_sewage.jpg',
      aiPredictions: detectedPayload?.rawPredictions || []
    };

    const res = await axios.post(`${BASE_URL}/api/complaints`, newComplaint);
    assert(res.status === 201 && res.data.success === true, 'POST /api/complaints registers complaint in database');
    assert(res.data.data.id.startsWith('AQG-'), 'Generated Complaint ID follows AquaGuard convention (AQG-XXXXX)');
    assert(res.data.data.departmentCode === 'SANITATION', 'Correctly persisted department code SANITATION');

    createdComplaintId = res.data.data.id;
    console.log(`     Created Complaint ID: ${createdComplaintId}`);
  } catch (e) {
    assert(false, `POST /api/complaints failed: ${e.response?.data?.error || e.message}`);
  }

  // 5. Query Complaints with Filters
  try {
    const listRes = await axios.get(`${BASE_URL}/api/complaints?department=SANITATION`);
    assert(listRes.status === 200 && listRes.data.success === true, 'GET /api/complaints filters by department');
    assert(listRes.data.data.some(c => c.id === createdComplaintId), 'Newly registered complaint appears in department filtered listing');
  } catch (e) {
    assert(false, `GET /api/complaints filter failed: ${e.message}`);
  }

  // 6. Update Status (Officer Lifecycle)
  if (createdComplaintId) {
    try {
      const updateRes = await axios.patch(`${BASE_URL}/api/complaints/${createdComplaintId}/status`, {
        status: 'IN PROGRESS',
        notes: 'Sanitary inspector team deployed to isolate drainage inlet.',
        officerRole: 'SANITATION_OFFICER'
      });
      assert(updateRes.status === 200 && updateRes.data.data.status === 'IN PROGRESS', 'PATCH /api/complaints/:id/status updates lifecycle to IN PROGRESS');

      const resolveRes = await axios.patch(`${BASE_URL}/api/complaints/${createdComplaintId}/status`, {
        status: 'RESOLVED',
        resolutionDetails: 'Well disinfected with potassium permanganate. Sewer line repaired.',
        notes: 'Well disinfected with potassium permanganate. Sewer line repaired.',
        officerRole: 'SANITATION_OFFICER'
      });
      assert(resolveRes.status === 200 && resolveRes.data.data.status === 'RESOLVED', 'PATCH /api/complaints/:id/status updates lifecycle to RESOLVED');
    } catch (e) {
      assert(false, `Status update failed: ${e.response?.data?.error || e.message}`);
    }
  }

  // 7. Dashboard Statistics
  try {
    const statsRes = await axios.get(`${BASE_URL}/api/stats/dashboard`);
    assert(statsRes.status === 200 && statsRes.data.success === true, 'GET /api/stats/dashboard computes real aggregation KPIs');
    assert(typeof statsRes.data.stats.totalComplaints === 'number' && statsRes.data.stats.totalComplaints > 0, 'Total complaints count is greater than zero');
    console.log(`     KPI Summary: Total=${statsRes.data.stats.totalComplaints}, Resolved=${statsRes.data.stats.resolvedCount}, Water=${statsRes.data.stats.waterSupplyIssues}, Sanitation=${statsRes.data.stats.sanitationIssues}, Env=${statsRes.data.stats.environmentIssues}`);
  } catch (e) {
    assert(false, `Dashboard stats failed: ${e.message}`);
  }

  console.log('\n========================================================');
  console.log(`🏁 TEST RESULTS: ${passed} PASSED | ${failed} FAILED`);
  console.log('========================================================');

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});

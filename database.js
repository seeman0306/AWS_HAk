/**
 * AquaGuard AI — Unified Database Engine
 * Prioritizes PostgreSQL REST API with LocalStorage resilient cache
 * AWS Environmental Hacks Hackathon
 */

(function () {
  'use strict';

  const DB_KEY = 'aquaguard_complaints_v1';
  const BACKEND_URL = (typeof window !== 'undefined' && window._AQUAGUARD_BACKEND_URL) || '';

  // Seed complaints for offline fallback
  const SEED_COMPLAINTS = [
    {
      id: 'AQG-7821A',
      userId: 'usr_citizen_01',
      userName: 'Kishore Sundar',
      issueType: 'drinking_water_contamination',
      issue: 'Suspected Contaminated Drinking Water',
      issueLabel: 'Suspected Contaminated Drinking Water',
      confidence: 0.892,
      severity: 'HIGH',
      departmentCode: 'WATER_SUPPLY',
      department: 'Water Supply & Quality Department',
      latitude: 9.524500,
      longitude: 77.638200,
      location: '9.524500, 77.638200',
      address: '14 North Car Street, Ward 3, Water Supply Sector',
      status: 'IN PROGRESS',
      imageUrl: 'assets/sample_drinking_water.jpg',
      waterSourceType: 'DRINKING_TAP',
      suspectedContaminant: 'TURBIDITY_ODOR',
      citizenDescription: 'Tap water coming with brownish discoloration and sulfur odor for 2 days.',
      notes: 'Water quality sample collected for laboratory TDS & microbial assay by field team.',
      date: '10 Oct 2026',
      time: '04:15 PM',
      timestamp: Date.now() - 14400000,
      officer: 'Dr. Rajesh Verma (Water Supply)'
    },
    {
      id: 'AQG-3942B',
      userId: 'usr_citizen_01',
      userName: 'Kishore Sundar',
      issueType: 'sewage_in_well',
      issue: 'Sewage Infiltration into Well Water',
      issueLabel: 'Sewage Infiltration into Community Open Well',
      confidence: 0.941,
      severity: 'HIGH',
      departmentCode: 'SANITATION',
      department: 'Sanitation & Sewerage Department',
      latitude: 9.516800,
      longitude: 77.629400,
      location: '9.516800, 77.629400',
      address: 'Opposite Sivan Temple Well, West Bazaar Ward',
      status: 'NEW',
      imageUrl: 'assets/sample_well_sewage.jpg',
      waterSourceType: 'OPEN_WELL',
      suspectedContaminant: 'SEWAGE',
      citizenDescription: 'Broken municipal underground sewer line overflowing directly into historical open well.',
      notes: 'Assigned to field sanitary inspector for emergency isolation.',
      date: '10 Oct 2026',
      time: '01:20 PM',
      timestamp: Date.now() - 25200000,
      officer: 'Eng. Meera Nair (Sanitation)'
    },
    {
      id: 'AQG-9104C',
      userId: 'usr_citizen_01',
      userName: 'Kishore Sundar',
      issueType: 'sewage_in_pond_lake',
      issue: 'Sewage & Waste Discharge into Pond/Lake',
      issueLabel: 'Sewage & Waste Discharge into Lotus Pond',
      confidence: 0.885,
      severity: 'MEDIUM',
      departmentCode: 'ENVIRONMENT',
      department: 'Environmental & Water Resources Board',
      latitude: 9.531200,
      longitude: 77.645100,
      location: '9.531200, 77.645100',
      address: 'East Lake Bund Road, Near Botanical Gardens',
      status: 'ASSIGNED',
      imageUrl: 'assets/sample_pond_pollution.jpg',
      waterSourceType: 'POND_LAKE',
      suspectedContaminant: 'FLOATING_WASTE',
      citizenDescription: 'Discharge of untreated wastewater and floating debris noticed at inlet channel.',
      notes: 'Notified Environmental Protection Officer for inlet barricade installation.',
      date: '09 Oct 2026',
      time: '11:45 AM',
      timestamp: Date.now() - 86400000,
      officer: 'Officer Ananya Sen (Environment)'
    },
    {
      id: 'AQG-6238D',
      userId: 'usr_citizen_01',
      userName: 'Kishore Sundar',
      issueType: 'sewage_pipe_leakage',
      issue: 'Sewage Pipe Leakage & Discharge',
      issueLabel: 'Underground Sewage Main Rupture',
      confidence: 0.923,
      severity: 'HIGH',
      departmentCode: 'SANITATION',
      department: 'Sanitation & Sewerage Department',
      latitude: 9.508900,
      longitude: 77.621500,
      location: '9.508900, 77.621500',
      address: 'Railway Feeder Road, Ward 11',
      status: 'RESOLVED',
      imageUrl: 'assets/sample_pipe_leak.jpg',
      waterSourceType: 'DRAINAGE',
      suspectedContaminant: 'SEWAGE',
      citizenDescription: 'Sewage water flooding onto pedestrian walkway near municipal borewell point.',
      notes: 'Broken 300mm stoneware pipe repaired and replaced with HDPE conduit. Area sanitized with bleaching powder.',
      date: '08 Oct 2026',
      time: '09:10 AM',
      timestamp: Date.now() - 172800000,
      officer: 'Eng. Meera Nair (Sanitation)'
    }
  ];

  // ============================================================
  // LOCAL STORAGE CACHE
  // ============================================================

  function loadAll() {
    try {
      const raw = localStorage.getItem(DB_KEY);
      if (!raw) return JSON.parse(JSON.stringify(SEED_COMPLAINTS));
      const data = JSON.parse(raw);
      return Array.isArray(data) && data.length ? data : JSON.parse(JSON.stringify(SEED_COMPLAINTS));
    } catch {
      return JSON.parse(JSON.stringify(SEED_COMPLAINTS));
    }
  }

  function saveAll(data) {
    try {
      localStorage.setItem(DB_KEY, JSON.stringify(data));
    } catch (e) {
      console.warn('[AquaGuard AI] Storage write failed:', e);
    }
  }

  function nextId() {
    const randomSuffix = Math.random().toString(36).substring(2, 6).toUpperCase() + String.fromCharCode(65 + Math.floor(Math.random() * 26));
    return 'AQG-' + randomSuffix;
  }

  // ============================================================
  // BACKEND CONNECTIVITY CHECK
  // ============================================================

  let backendAvailable = null;

  async function checkBackend() {
    if (backendAvailable !== null) return backendAvailable;
    try {
      const ctrl = new AbortController();
      const tid = setTimeout(() => ctrl.abort(), 2000);
      const r = await fetch(`${BACKEND_URL}/api/health`, { signal: ctrl.signal });
      clearTimeout(tid);
      backendAvailable = r.ok;
    } catch {
      backendAvailable = false;
    }
    return backendAvailable;
  }

  async function apiGet(path) {
    const r = await fetch(`${BACKEND_URL}${path}`, { headers: { 'Content-Type': 'application/json' } });
    if (!r.ok) throw new Error(`API error ${r.status}`);
    return r.json();
  }

  async function apiPost(path, body) {
    const r = await fetch(`${BACKEND_URL}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    if (!r.ok) throw new Error(`API error ${r.status}`);
    return r.json();
  }

  async function apiPatch(path, body) {
    const r = await fetch(`${BACKEND_URL}${path}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    if (!r.ok) throw new Error(`API error ${r.status}`);
    return r.json();
  }

  // ============================================================
  // SUBSCRIBER SYSTEM
  // ============================================================

  const subscribers = [];
  function notify() {
    subscribers.forEach(fn => {
      try { fn(); } catch (e) { console.error(e); }
    });
  }

  // ============================================================
  // PUBLIC DATABASE API
  // ============================================================

  const CivicDB = {
    subscribe(fn) {
      subscribers.push(fn);
    },

    async getComplaints(filter = {}) {
      if (await checkBackend()) {
        try {
          const params = new URLSearchParams();
          if (filter.department) params.append('department', filter.department);
          if (filter.status) params.append('status', filter.status);
          if (filter.severity) params.append('severity', filter.severity);
          if (filter.search) params.append('search', filter.search);

          const query = params.toString() ? `?${params.toString()}` : '';
          const res = await apiGet(`/api/complaints${query}`);
          if (res.data) {
            saveAll(res.data);
            return res.data;
          }
        } catch (e) {
          console.warn('[AquaGuard AI] Backend fetch failed, falling back to local cache', e.message);
        }
      }
      return loadAll();
    },

    async getComplaintById(id) {
      const all = await this.getComplaints();
      return all.find(c => c.id === id) || null;
    },

    async addComplaint(data) {
      const id = data.id || nextId();
      const record = {
        id,
        timestamp: Date.now(),
        date: data.date || new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }),
        time: data.time || new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
        status: 'NEW',
        ...data
      };

      if (await checkBackend()) {
        try {
          const res = await apiPost('/api/complaints', record);
          if (res.data) {
            const all = loadAll();
            all.unshift(res.data);
            saveAll(all);
            notify();
            return res.data;
          }
        } catch (e) {
          console.error('[AquaGuard AI] addComplaint backend call failed:', e);
        }
      }

      const all = loadAll();
      all.unshift(record);
      saveAll(all);
      notify();
      return record;
    },

    async updateStatus(id, status, notes, resolutionDetails) {
      const user = JSON.parse(localStorage.getItem('civiceye-user') || '{}');
      const payload = {
        status,
        notes,
        resolutionDetails,
        officerRole: user.role || 'OVERALL_ADMIN',
        departmentCode: user.departmentCode || null
      };

      if (await checkBackend()) {
        try {
          const res = await apiPatch(`/api/complaints/${id}/status`, payload);
          if (res.data) {
            const all = loadAll();
            const idx = all.findIndex(c => c.id === id);
            if (idx !== -1) all[idx] = res.data;
            saveAll(all);
            notify();
            return res.data;
          }
        } catch (e) {
          console.error('[AquaGuard AI] updateStatus backend call failed:', e);
        }
      }

      const all = loadAll();
      const idx = all.findIndex(c => c.id === id);
      if (idx === -1) return null;
      all[idx].status = status;
      if (notes) all[idx].notes = notes;
      if (resolutionDetails) all[idx].resolutionDetails = resolutionDetails;
      saveAll(all);
      notify();
      return all[idx];
    },

    async reassignDepartment(id, departmentCode, notes) {
      if (await checkBackend()) {
        try {
          const res = await apiPatch(`/api/complaints/${id}/department`, { departmentCode, notes });
          if (res.data) {
            notify();
            return res.data;
          }
        } catch (e) {
          console.error('[AquaGuard AI] reassignDepartment backend call failed:', e);
        }
      }

      const all = loadAll();
      const item = all.find(c => c.id === id);
      if (item) {
        item.departmentCode = departmentCode;
        saveAll(all);
        notify();
      }
      return item;
    },

    async getStats() {
      if (await checkBackend()) {
        try {
          const res = await apiGet('/api/stats/dashboard');
          if (res.stats) return res.stats;
        } catch (e) {
          console.warn('[AquaGuard AI] getStats API failed, computing from local cache');
        }
      }

      const all = loadAll();
      const stats = {
        totalComplaints: all.length,
        openUnresolved: all.filter(c => c.status !== 'RESOLVED' && c.status !== 'REJECTED').length,
        highPriorityPending: all.filter(c => c.severity === 'HIGH' && c.status !== 'RESOLVED').length,
        waterSupplyIssues: all.filter(c => c.departmentCode === 'WATER_SUPPLY').length,
        sanitationIssues: all.filter(c => c.departmentCode === 'SANITATION').length,
        environmentIssues: all.filter(c => c.departmentCode === 'ENVIRONMENT').length,
        newCount: all.filter(c => c.status === 'NEW').length,
        assignedCount: all.filter(c => c.status === 'ASSIGNED').length,
        inProgressCount: all.filter(c => c.status === 'IN PROGRESS').length,
        resolvedCount: all.filter(c => c.status === 'RESOLVED').length,
        rejectedCount: all.filter(c => c.status === 'REJECTED').length
      };
      return stats;
    },

    async exportJSON() {
      return JSON.stringify(await this.getComplaints(), null, 2);
    },

    async resetToDefault() {
      saveAll(JSON.parse(JSON.stringify(SEED_COMPLAINTS)));
      notify();
    }
  };

  window.CivicDB = CivicDB;
  window.AquaGuardDB = CivicDB; // Alias for modern naming

  // Initial local seed if empty
  if (!localStorage.getItem(DB_KEY)) {
    saveAll(JSON.parse(JSON.stringify(SEED_COMPLAINTS)));
  }
})();

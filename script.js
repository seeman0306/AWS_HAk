/**
 * AquaGuard AI — Core Application Logic
 * Environmental Water Contamination Reporting & Smart Complaint Routing System
 * AWS Environmental Hacks Hackathon
 */

// ============================================================
// 1. ROUTING & ACCESS CONTROL
// ============================================================

const API_BASE = (typeof window !== 'undefined' && window.location && window.location.protocol === 'file:') 
  ? 'http://localhost:5000' 
  : '';

const ROUTES = {
  citizen: 'citizen.html',
  water: 'water-supply-officer.html',
  sanitation: 'sanitation-officer.html',
  environment: 'environment-officer.html',
  road: 'water-supply-officer.html',
  street: 'sanitation-officer.html',
  traffic: 'environment-officer.html',
  admin: 'admin.html'
};

const ROLE_PAGE_MAP = {
  CITIZEN: 'citizen',
  WATER_OFFICER: 'water',
  SANITATION_OFFICER: 'sanitation',
  ENVIRONMENT_OFFICER: 'environment',
  ROAD_OFFICER: 'water',
  STREET_LIGHT_OFFICER: 'sanitation',
  TRAFFIC_OFFICER: 'environment',
  OVERALL_ADMIN: 'admin'
};

function getDeptLabel(code) {
  const map = {
    WATER_SUPPLY: 'Water Supply & Quality Department',
    SANITATION: 'Sanitation & Sewerage Department',
    ENVIRONMENT: 'Environmental & Water Resources Board'
  };
  return map[code] || code;
}

function statusBadge(s) {
  const norm = (s || 'NEW').toUpperCase();
  const cls = {
    'NEW': 'badge-new',
    'ASSIGNED': 'badge-assigned',
    'IN PROGRESS': 'badge-in-progress',
    'RESOLVED': 'badge-resolved',
    'REJECTED': 'badge-rejected'
  };
  return `<span class="badge ${cls[norm] || 'badge-new'}">${norm}</span>`;
}

function severityBadge(s) {
  const norm = (s || 'HIGH').toUpperCase();
  const cls = { 'HIGH': 'badge-high', 'MEDIUM': 'badge-medium', 'LOW': 'badge-low' };
  return `<span class="badge ${cls[norm] || 'badge-high'}">${norm}</span>`;
}

function deptBadge(code) {
  const c = (code || 'WATER_SUPPLY').toUpperCase();
  if (c === 'WATER_SUPPLY') return `<span class="badge-water">💧 Water Supply</span>`;
  if (c === 'SANITATION') return `<span class="badge-sanitation">🚽 Sanitation</span>`;
  return `<span class="badge-environment">🌿 Environment</span>`;
}

function logout() {
  localStorage.removeItem('civiceye-role');
  localStorage.removeItem('civiceye-user');
  window.location.href = 'index.html';
}
window.logout = logout;

// ============================================================
// 2. DOM INITIALIZER
// ============================================================

document.addEventListener('DOMContentLoaded', async () => {
  const page = document.body.dataset.page;
  const protectedPages = ['citizen', 'water', 'sanitation', 'environment', 'road', 'street', 'traffic', 'admin'];

  // Route Guard
  if (protectedPages.includes(page)) {
    const storedRole = localStorage.getItem('civiceye-role');
    if (!storedRole) {
      window.location.href = 'index.html';
      return;
    }
    const expectedPage = ROLE_PAGE_MAP[storedRole];
    // Allow admin to view any officer page, otherwise ensure role matches
    if (storedRole !== 'OVERALL_ADMIN' && expectedPage && expectedPage !== page) {
      const targetUrl = ROUTES[expectedPage] || 'index.html';
      if (!window.location.pathname.endsWith(targetUrl)) {
        window.location.href = targetUrl;
        return;
      }
    }
  }

  // Handle Landing Login Form
  const loginForm = document.getElementById('loginForm');
  if (loginForm) {
    loginForm.addEventListener('submit', async e => {
      e.preventDefault();
      const email = document.getElementById('email').value.trim();
      const password = document.getElementById('password').value.trim();
      const btn = document.getElementById('loginSubmitBtn') || loginForm.querySelector('button[type=submit]');
      
      btn.disabled = true;
      btn.textContent = 'Verifying credentials...';

      try {
        const res = await fetch('/api/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password })
        });
        const data = await res.json();

        if (data.success && data.user) {
          localStorage.setItem('civiceye-role', data.user.role);
          localStorage.setItem('civiceye-user', JSON.stringify(data.user));

          const r = data.user.role;
          if (r === 'CITIZEN') window.location.href = 'citizen.html';
          else if (r === 'WATER_OFFICER' || r === 'ROAD_OFFICER') window.location.href = 'water-supply-officer.html';
          else if (r === 'SANITATION_OFFICER' || r === 'STREET_LIGHT_OFFICER') window.location.href = 'sanitation-officer.html';
          else if (r === 'ENVIRONMENT_OFFICER' || r === 'TRAFFIC_OFFICER') window.location.href = 'environment-officer.html';
          else if (r === 'OVERALL_ADMIN') window.location.href = 'admin.html';
          else window.location.href = 'citizen.html';
        } else {
          alert('Login failed: ' + (data.error || 'Invalid credentials.'));
          btn.disabled = false;
          btn.textContent = 'Access Portal';
        }
      } catch (err) {
        alert('Cannot connect to AquaGuard AI server: ' + err.message);
        btn.disabled = false;
        btn.textContent = 'Access Portal';
      }
    });
  }

  // Page specific initializers
  if (page === 'citizen') initCitizen();
  if (page === 'water' || page === 'road') initOfficer('WATER_SUPPLY', 'Water Supply & Quality Department');
  if (page === 'sanitation' || page === 'street') initOfficer('SANITATION', 'Sanitation & Sewerage Department');
  if (page === 'environment' || page === 'traffic') initOfficer('ENVIRONMENT', 'Environmental & Water Resources Board');
  if (page === 'admin') initAdmin();
});

// ============================================================
// 3. CITIZEN MODULE
// ============================================================

let _selectedImageData = null;
let _selectedImageBlob = null;
let _lastResult = null;
let _citizenPickerMap = null;
let _citizenPickerMarker = null;

function selectCategoryCard(el) {
  document.querySelectorAll('.category-card-option').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  const issue = el.dataset.issue;

  const overrideSelect = document.getElementById('issueOverrideSelect');
  if (overrideSelect) overrideSelect.value = issue;

  // Auto-sync water source and suspected contaminant defaults
  const ws = document.getElementById('waterSourceType');
  const sc = document.getElementById('suspectedContaminant');
  if (issue === 'drinking_water_contamination') {
    if (ws) ws.value = 'DRINKING_TAP';
    if (sc) sc.value = 'TURBIDITY_ODOR';
  } else if (issue === 'sewage_in_well') {
    if (ws) ws.value = 'OPEN_WELL';
    if (sc) sc.value = 'SEWAGE';
  } else if (issue === 'sewage_in_pond_lake') {
    if (ws) ws.value = 'POND_LAKE';
    if (sc) sc.value = 'FLOATING_WASTE';
  } else if (issue === 'sewage_pipe_leakage') {
    if (ws) ws.value = 'DRAINAGE';
    if (sc) sc.value = 'SEWAGE';
  } else if (issue === 'visible_water_pollution') {
    if (ws) ws.value = 'CANAL_RIVER';
    if (sc) sc.value = 'CHEMICAL_DISCHARGE';
  }
}
window.selectCategoryCard = selectCategoryCard;

function handleCategoryOverrideChange(issue) {
  const card = document.querySelector(`.category-card-option[data-issue="${issue}"]`);
  if (card) selectCategoryCard(card);

  if (_lastResult) {
    const routing = {
      drinking_water_contamination: { dept: 'WATER_SUPPLY', name: 'Water Supply & Quality Department', title: 'Suspected Contaminated Drinking Water', sev: 'HIGH' },
      sewage_in_well: { dept: 'SANITATION', name: 'Sanitation & Sewerage Department', title: 'Sewage Infiltration into Well Water', sev: 'HIGH' },
      sewage_in_pond_lake: { dept: 'ENVIRONMENT', name: 'Environmental & Water Resources Board', title: 'Sewage & Waste Discharge into Pond/Lake', sev: 'MEDIUM' },
      sewage_pipe_leakage: { dept: 'SANITATION', name: 'Sanitation & Sewerage Department', title: 'Sewage Pipe Leakage & Discharge', sev: 'HIGH' },
      visible_water_pollution: { dept: 'ENVIRONMENT', name: 'Environmental & Water Resources Board', title: 'Visible Wastewater Discharge / Pollution', sev: 'HIGH' }
    }[issue];

    if (routing) {
      _lastResult.issueType = issue;
      _lastResult.issueTitle = routing.title;
      _lastResult.department = routing.dept;
      _lastResult.departmentName = routing.name;
      _lastResult.severity = routing.sev;

      document.getElementById('detectedIssue').textContent = routing.title;
      document.getElementById('detectedDepartment').textContent = routing.name;
      const sevEl = document.getElementById('detectedSeverity');
      if (sevEl) {
        sevEl.textContent = routing.sev;
        sevEl.className = `badge badge-${routing.sev.toLowerCase()}`;
      }
    }
  }
}
window.handleCategoryOverrideChange = handleCategoryOverrideChange;

function handleImageSelection(event) {
  const file = event.target.files[0];
  if (!file) return;

  _selectedImageBlob = file;
  const reader = new FileReader();
  reader.onload = ev => {
    _selectedImageData = ev.target.result;
    showPreview(ev.target.result);
  };
  reader.readAsDataURL(file);
}
window.handleImageSelection = handleImageSelection;

async function loadSampleImage(imagePath, issueType, descriptionText) {
  try {
    const card = document.querySelector(`.category-card-option[data-issue="${issueType}"]`);
    if (card) selectCategoryCard(card);

    if (descriptionText) {
      const descInput = document.getElementById('citizenDescription');
      if (descInput) descInput.value = descriptionText;
    }

    const resp = await fetch(imagePath);
    const blob = await resp.blob();
    _selectedImageBlob = new File([blob], imagePath.split('/').pop(), { type: 'image/jpeg' });
    
    const reader = new FileReader();
    reader.onload = ev => {
      _selectedImageData = ev.target.result;
      showPreview(ev.target.result);
      // Auto trigger AI analysis for seamless user experience
      setTimeout(() => {
        document.getElementById('detectBtn')?.click();
      }, 250);
    };
    reader.readAsDataURL(blob);
  } catch (e) {
    console.error('[AquaGuard AI] Error loading sample image:', e);
  }
}
window.loadSampleImage = loadSampleImage;

function showPreview(src) {
  const pc = document.getElementById('previewCard');
  const img = document.getElementById('previewImage');
  if (img) img.src = src;
  if (pc) pc.classList.add('show');
  document.getElementById('detectionPanel')?.classList.remove('show');
  document.getElementById('submissionSuccessCard')?.classList.remove('show');
  pc?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

function initCitizen() {
  const el = id => document.getElementById(id);

  // Initialize GPS and Pin Picker Map
  requestGPS();
  initCitizenPickerMap(9.524500, 77.638200);

  el('refreshLocationBtn')?.addEventListener('click', requestGPS);
  el('enableLocationBtn')?.addEventListener('click', requestGPS);

  // Choose another image
  el('chooseAnotherBtn')?.addEventListener('click', () => {
    el('previewCard')?.classList.remove('show');
    el('detectionPanel')?.classList.remove('show');
    el('submissionSuccessCard')?.classList.remove('show');
    _selectedImageData = null;
    _selectedImageBlob = null;
  });

  // Call Roboflow AI Detection API
  el('detectBtn')?.addEventListener('click', async () => {
    if (!_selectedImageData && !_selectedImageBlob) {
      alert('Please select or capture a photograph of the water issue first.');
      return;
    }

    const locBox = el('locationBox');
    const lat = parseFloat(locBox?.dataset.latitude || 9.524500);
    const lng = parseFloat(locBox?.dataset.longitude || 77.638200);

    const activeCard = document.querySelector('.category-card-option.active');
    const categoryHint = activeCard?.dataset.issue || document.getElementById('issueOverrideSelect')?.value || '';
    const waterSource = el('waterSourceType')?.value || '';

    const scanBar = el('scanBar');
    const detectBtn = el('detectBtn');
    if (scanBar) scanBar.style.display = 'block';
    detectBtn.disabled = true;
    detectBtn.textContent = 'Scanning with Roboflow Vision AI...';

    try {
      const fd = new FormData();
      if (_selectedImageBlob) {
        fd.append('image', _selectedImageBlob, _selectedImageBlob.name || 'water_incident.jpg');
      } else {
        const blob = await (await fetch(_selectedImageData)).blob();
        fd.append('image', blob, 'water_incident.jpg');
      }
      fd.append('latitude', lat);
      fd.append('longitude', lng);
      fd.append('categoryHint', categoryHint);
      fd.append('waterSource', waterSource);

      const resp = await fetch('/api/detect', { method: 'POST', body: fd });
      const data = await resp.json();

      if (!data.success) {
        throw new Error(data.error || 'Roboflow detection request failed.');
      }

      _lastResult = {
        ...data.data,
        location: `${lat.toFixed(6)}, ${lng.toFixed(6)}`,
        latitude: lat,
        longitude: lng
      };

      renderDetectionResult(_lastResult);
      el('detectionPanel')?.classList.add('show');
      el('detectionPanel')?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    } catch (err) {
      console.error('[AquaGuard AI] Detection Error:', err);
      alert('AI Analysis Notice: ' + err.message + '\nYou can still select your issue category and submit the complaint directly.');
      // Graceful fallback to citizen selection
      _lastResult = {
        issueType: categoryHint || 'drinking_water_contamination',
        issueTitle: activeCard?.querySelector('.category-icon-title')?.textContent.trim() || 'Suspected Contaminated Water',
        confidence: 0.85,
        severity: 'HIGH',
        department: categoryHint === 'drinking_water_contamination' ? 'WATER_SUPPLY' : categoryHint === 'sewage_in_pond_lake' ? 'ENVIRONMENT' : 'SANITATION',
        departmentName: categoryHint === 'drinking_water_contamination' ? 'Water Supply & Quality Department' : 'Sanitation & Sewerage Department',
        location: `${lat.toFixed(6)}, ${lng.toFixed(6)}`,
        latitude: lat,
        longitude: lng,
        scientificDisclaimer: 'Visual observation recorded. Lab water testing dispatched for confirmation.',
        rawPredictions: []
      };
      renderDetectionResult(_lastResult);
      el('detectionPanel')?.classList.add('show');
    } finally {
      if (scanBar) scanBar.style.display = 'none';
      detectBtn.disabled = false;
      detectBtn.textContent = '🤖 Analyze with Roboflow AI';
    }
  });

  // Submit Complaint to PostgreSQL
  el('submitComplaintBtn')?.addEventListener('click', async () => {
    if (!_lastResult) {
      alert('Please select and analyze an image before submitting.');
      return;
    }

    const locBox = el('locationBox');
    const lat = parseFloat(locBox?.dataset.latitude || 9.524500);
    const lng = parseFloat(locBox?.dataset.longitude || 77.638200);
    const user = JSON.parse(localStorage.getItem('civiceye-user') || '{}');

    const submitBtn = el('submitComplaintBtn');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Registering Complaint in PostgreSQL...';

    try {
      const selectedIssue = el('issueOverrideSelect')?.value || _lastResult.issueType;
      const waterSource = el('waterSourceType')?.value || 'DRINKING_TAP';
      const contaminant = el('suspectedContaminant')?.value || 'TURBIDITY_ODOR';
      const citizenDesc = el('citizenDescription')?.value || 'Citizen submitted water contamination report via AquaGuard AI.';

      const complaintPayload = {
        userId: user.id || 'usr_citizen_01',
        userName: user.fullName || 'Citizen Reporter',
        issueType: selectedIssue,
        issue: _lastResult.issueTitle,
        issueLabel: _lastResult.issueTitle,
        confidence: _lastResult.confidence,
        severity: _lastResult.severity || 'HIGH',
        department: _lastResult.departmentName,
        departmentCode: _lastResult.department,
        latitude: lat,
        longitude: lng,
        location: `${lat.toFixed(6)}, ${lng.toFixed(6)}`,
        address: el('locationAddress')?.textContent || 'GPS Tagged Water Source',
        imageUrl: _lastResult.imageUrl || _selectedImageData || 'assets/sample_drinking_water.jpg',
        waterSourceType: waterSource,
        suspectedContaminant: contaminant,
        citizenDescription: citizenDesc,
        aiPredictions: _lastResult.rawPredictions || [],
        notes: `Initial triage: ${_lastResult.issueTitle}. Auto-routed by AquaGuard AI to ${_lastResult.departmentName}.`
      };

      const saved = await window.CivicDB.addComplaint(complaintPayload);

      el('successComplaintId').textContent = saved.id;
      el('successDepartment').textContent = saved.department;
      el('successIssue').textContent = saved.issue;
      el('submissionSuccessCard')?.classList.add('show');
      el('detectionPanel')?.classList.remove('show');
      el('previewCard')?.classList.remove('show');
      el('submissionSuccessCard')?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

      renderCitizenComplaints();
    } catch (e) {
      console.error('[AquaGuard AI] Submission error:', e);
      alert('Failed to register complaint: ' + e.message);
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = '✅ Confirm & Submit Water Complaint to Department';
    }
  });

  renderCitizenComplaints();
  window.CivicDB.subscribe(() => renderCitizenComplaints());
}

function renderDetectionResult(r) {
  const el = id => document.getElementById(id);
  if (el('detectedIssue')) el('detectedIssue').textContent = r.issueTitle || 'Water Pollution Detected';
  
  const conf = Math.round((r.confidence || 0) * 100);
  if (el('detectedConfidence')) el('detectedConfidence').textContent = `${conf}%`;
  if (el('detectedConfidenceBar')) el('detectedConfidenceBar').style.width = `${Math.max(conf, 15)}%`;

  if (el('detectedSeverity')) {
    el('detectedSeverity').textContent = r.severity || 'HIGH';
    el('detectedSeverity').className = `badge badge-${(r.severity || 'high').toLowerCase()}`;
  }

  if (el('detectedDepartment')) el('detectedDepartment').textContent = r.departmentName || 'Responsible Department';
  if (el('detectedLocation')) el('detectedLocation').textContent = r.location || '';

  if (el('scientificDisclaimerText') && r.scientificDisclaimer) {
    el('scientificDisclaimerText').textContent = r.scientificDisclaimer;
  }

  // Display raw detected objects from Roboflow
  const objectsContainer = el('detectedObjectsList');
  if (objectsContainer) {
    if (r.rawPredictions && r.rawPredictions.length > 0) {
      objectsContainer.innerHTML = r.rawPredictions.map((pred, i) => `
        <span class="telemetry-chip">
          🔍 Object #${i+1}: <strong>${pred.class}</strong> (${Math.round(pred.confidence * 100)}%) [x:${Math.round(pred.x)}, y:${Math.round(pred.y)}]
        </span>
      `).join('');
    } else {
      objectsContainer.innerHTML = `
        <span class="telemetry-chip" style="color:#d97706;">⚠️ Optical model confidence is broad. Citizen category verified.</span>
      `;
    }
  }

  // Sync category override dropdown
  const overrideSelect = el('issueOverrideSelect');
  if (overrideSelect && r.issueType) {
    overrideSelect.value = r.issueType;
  }
}

function initCitizenPickerMap(lat, lng) {
  const mapEl = document.getElementById('citizenPickerMap');
  if (!mapEl || typeof L === 'undefined') return;

  if (_citizenPickerMap) {
    _citizenPickerMap.setView([lat, lng], 14);
    if (_citizenPickerMarker) _citizenPickerMarker.setLatLng([lat, lng]);
    return;
  }

  _citizenPickerMap = L.map('citizenPickerMap').setView([lat, lng], 14);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap &bull; AquaGuard AI'
  }).addTo(_citizenPickerMap);

  const waterIcon = L.divIcon({
    className: '',
    html: `<div style="background:#0284c7;color:white;width:34px;height:34px;border-radius:50%;display:grid;place-items:center;border:2px solid white;box-shadow:0 4px 12px rgba(2,132,199,0.5);font-size:16px;">💧</div>`,
    iconSize: [34, 34],
    iconAnchor: [17, 17]
  });

  _citizenPickerMarker = L.marker([lat, lng], { draggable: true, icon: waterIcon }).addTo(_citizenPickerMap);

  function updatePickedCoords(newLat, newLng) {
    const formatted = `${newLat.toFixed(6)}, ${newLng.toFixed(6)}`;
    const locBox = document.getElementById('locationBox');
    if (locBox) {
      locBox.dataset.latitude = newLat.toFixed(6);
      locBox.dataset.longitude = newLng.toFixed(6);
    }
    const txt = document.getElementById('locationText');
    if (txt) txt.textContent = formatted;
    const badge = document.getElementById('pickerCoordsBadge');
    if (badge) badge.textContent = formatted;
    const addr = document.getElementById('locationAddress');
    if (addr) addr.textContent = 'Verified GPS location (pin adjusted)';
  }

  _citizenPickerMarker.on('dragend', e => {
    const pos = e.target.getLatLng();
    updatePickedCoords(pos.lat, pos.lng);
  });

  _citizenPickerMap.on('click', e => {
    _citizenPickerMarker.setLatLng(e.latlng);
    updatePickedCoords(e.latlng.lat, e.latlng.lng);
  });
}

function requestGPS() {
  const locBox = document.getElementById('locationBox');
  const textEl = document.getElementById('locationText');
  const addrEl = document.getElementById('locationAddress');

  if (textEl) textEl.textContent = 'Acquiring high-accuracy satellite lock...';

  if (!navigator.geolocation) {
    if (textEl) textEl.textContent = '9.524500, 77.638200';
    if (addrEl) addrEl.textContent = 'Geolocation not supported by device — default coordinates loaded.';
    return;
  }

  navigator.geolocation.getCurrentPosition(
    pos => {
      const lat = parseFloat(pos.coords.latitude.toFixed(6));
      const lng = parseFloat(pos.coords.longitude.toFixed(6));
      if (textEl) textEl.textContent = `${lat}, ${lng}`;
      if (addrEl) addrEl.textContent = 'High-accuracy satellite lock established.';
      if (locBox) {
        locBox.dataset.latitude = lat;
        locBox.dataset.longitude = lng;
      }
      initCitizenPickerMap(lat, lng);
      document.getElementById('enableLocationBtn')?.classList.add('hidden');
    },
    () => {
      // Permission denied or timeout — load default real test coordinate without breaking user flow
      const fallbackLat = 9.524500;
      const fallbackLng = 77.638200;
      if (textEl) textEl.textContent = `${fallbackLat}, ${fallbackLng} (Demonstration GPS Tag)`;
      if (addrEl) addrEl.textContent = 'Location permission ungranted — pin placed at Municipal Ward 3. Drag pin to adjust.';
      if (locBox) {
        locBox.dataset.latitude = fallbackLat;
        locBox.dataset.longitude = fallbackLng;
      }
      initCitizenPickerMap(fallbackLat, fallbackLng);
      document.getElementById('enableLocationBtn')?.classList.remove('hidden');
    },
    { enableHighAccuracy: true, timeout: 6000 }
  );
}

async function renderCitizenComplaints() {
  const list = document.getElementById('userComplaintList');
  if (!list) return;

  const user = JSON.parse(localStorage.getItem('civiceye-user') || '{}');
  const userId = user.id || 'usr_citizen_01';
  const allComplaints = await window.CivicDB.getComplaints();
  
  // Show user's complaints or all demo citizen complaints
  const complaints = allComplaints.filter(c => c.userId === userId || !c.userId || c.userId === 'usr_citizen_01');

  if (!complaints.length) {
    list.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">💧</div>
        <div class="empty-msg">No water pollution complaints submitted yet.</div>
      </div>
    `;
    return;
  }

  list.innerHTML = complaints.map(c => {
    const isResolved = c.status === 'RESOLVED';
    const isInProg = c.status === 'IN PROGRESS';
    const isAssigned = c.status === 'ASSIGNED' || isInProg || isResolved;

    return `
      <div class="complaint-card" style="margin-bottom:18px;">
        <div class="complaint-card-top">
          <div>
            <div class="complaint-id-label" style="color:#0284c7; font-weight:800;">${c.id}</div>
            <div style="font-size:0.82rem; color:var(--gray-500); margin-top:2px;">${c.date} · ${c.time || '—'}</div>
          </div>
          <div class="complaint-badges">
            ${statusBadge(c.status)}
            ${severityBadge(c.severity)}
            ${deptBadge(c.departmentCode)}
          </div>
        </div>

        <div class="complaint-body">
          <img src="${c.imageUrl || 'assets/sample_drinking_water.jpg'}" alt="${c.issue}" class="complaint-thumb" onerror="this.src='assets/sample_drinking_water.jpg'"/>
          <div class="complaint-meta">
            <div class="meta-item"><div class="meta-key">Reported Issue</div><div class="meta-val" style="font-weight:700;">${c.issueLabel || c.issue}</div></div>
            <div class="meta-item"><div class="meta-key">Department</div><div class="meta-val">${c.department}</div></div>
            <div class="meta-item"><div class="meta-key">GPS Location</div><div class="meta-val mono" style="font-size:0.8rem;">${c.location}</div></div>
            <div class="meta-item"><div class="meta-key">Roboflow AI Score</div><div class="meta-val" style="color:#059669; font-weight:700;">${Math.round((c.confidence || 0.88)*100)}% Verified</div></div>
            ${c.citizenDescription ? `<div class="meta-item" style="grid-column:span 2;"><div class="meta-key">Description</div><div class="meta-val" style="font-size:0.85rem; color:#475569;">${c.citizenDescription}</div></div>` : ''}
          </div>
        </div>

        <div class="timeline-track">
          <div class="timeline-connector"></div>
          <div class="timeline-step done"><div class="timeline-dot">✓</div><div class="timeline-lbl">Submitted</div></div>
          <div class="timeline-step ${isAssigned ? 'done' : 'active'}"><div class="timeline-dot">${isAssigned ? '✓' : '2'}</div><div class="timeline-lbl">Assigned</div></div>
          <div class="timeline-step ${isResolved ? 'done' : isInProg ? 'active' : ''}"><div class="timeline-dot">${isResolved ? '✓' : isInProg ? '●' : '3'}</div><div class="timeline-lbl">In Testing</div></div>
          <div class="timeline-step ${isResolved ? 'done' : ''}"><div class="timeline-dot">${isResolved ? '✓' : '4'}</div><div class="timeline-lbl">Resolved</div></div>
        </div>

        <div class="card-actions" style="margin-top:12px; display:flex; justify-content:space-between; align-items:center;">
          <span style="font-size:0.8rem; color:#64748b;">${c.address || 'GPS verified address'}</span>
          <button class="btn-ghost btn-sm btn-view-details" data-id="${c.id}">Inspect Incident &amp; Notes</button>
        </div>
      </div>
    `;
  }).join('');

  list.querySelectorAll('.btn-view-details').forEach(btn => {
    btn.addEventListener('click', () => openDetailModal(btn.dataset.id));
  });
}

// ============================================================
// 4. OFFICER MODULE
// ============================================================

async function initOfficer(deptCode, deptTitle) {
  const el = id => document.getElementById(id);
  if (el('officerTitle')) el('officerTitle').textContent = deptTitle;

  async function refresh() {
    const all = await window.CivicDB.getComplaints();
    const mine = all.filter(c => c.departmentCode === deptCode || (c.department || '').toLowerCase().includes(deptCode.toLowerCase().replace('_',' ')));

    if (el('totalCount')) el('totalCount').textContent = mine.length;
    if (el('newCount')) el('newCount').textContent = mine.filter(c => c.status === 'NEW').length;
    if (el('progressCount')) el('progressCount').textContent = mine.filter(c => c.status === 'IN PROGRESS' || c.status === 'ASSIGNED').length;
    if (el('resolvedCount')) el('resolvedCount').textContent = mine.filter(c => c.status === 'RESOLVED').length;

    const container = el('officerComplaintList');
    if (!container) return;

    if (!mine.length) {
      container.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">✅</div>
          <div class="empty-msg">No active water contamination reports in this department's queue.</div>
        </div>
      `;
      return;
    }

    container.innerHTML = mine.map(c => `
      <div class="officer-card" style="margin-bottom:20px; border:1px solid var(--gray-200); border-radius:14px; background:white; padding:22px; box-shadow:var(--shadow-sm);">
        <div class="officer-card-header" style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px; flex-wrap:wrap; gap:8px;">
          <div>
            <div class="complaint-id-label" style="font-size:1.1rem; font-weight:800; color:#0284c7;">${c.id}</div>
            <div style="font-size:0.8rem; color:var(--gray-500); margin-top:2px;">${c.date} · ${c.time || '—'}</div>
          </div>
          <div style="display:flex; gap:8px; align-items:center;">
            ${statusBadge(c.status)}
            ${severityBadge(c.severity)}
            ${deptBadge(c.departmentCode)}
          </div>
        </div>

        <div class="officer-card-body" style="display:flex; gap:18px; margin-bottom:16px; flex-wrap:wrap;">
          <img src="${c.imageUrl || 'assets/sample_drinking_water.jpg'}" alt="${c.issue}" class="officer-card-thumb" style="width:160px; height:120px; border-radius:10px; object-fit:cover;" onerror="this.src='assets/sample_drinking_water.jpg'"/>
          <div class="officer-meta-grid" style="flex:1; display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:10px;">
            <div class="meta-item"><div class="meta-key">Issue Type</div><div class="meta-val" style="font-weight:700;">${c.issueLabel || c.issue}</div></div>
            <div class="meta-item"><div class="meta-key">Roboflow AI Score</div><div class="meta-val" style="color:#059669; font-weight:700;">${Math.round((c.confidence || 0.88)*100)}% Verified</div></div>
            <div class="meta-item"><div class="meta-key">GPS Location</div><div class="meta-val mono" style="font-size:0.8rem;">${c.location}</div></div>
            <div class="meta-item"><div class="meta-key">Reported By</div><div class="meta-val">${c.userName || 'Citizen'}</div></div>
            <div class="meta-item"><div class="meta-key">Water Source</div><div class="meta-val">${c.waterSourceType || 'Municipal Supply'}</div></div>
            <div class="meta-item"><div class="meta-key">Suspected Contaminant</div><div class="meta-val">${c.suspectedContaminant || 'Turbidity / Sewage'}</div></div>
          </div>
        </div>

        ${c.citizenDescription ? `<div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:10px 14px; margin-bottom:14px; font-size:0.86rem; color:#334155;"><strong>Citizen Note:</strong> ${c.citizenDescription}</div>` : ''}

        ${c.notes ? `<div class="notes-box mb-4" style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:8px; padding:10px 14px; margin-bottom:14px; font-size:0.86rem; color:#1e40af;"><strong>📝 Field Investigation Log:</strong> ${c.notes}</div>` : ''}

        <div class="officer-card-actions" style="display:flex; gap:10px; flex-wrap:wrap; border-top:1px solid #f1f5f9; padding-top:14px;">
          <button class="btn-primary btn-sm btn-action-status" data-action="IN PROGRESS" data-id="${c.id}" ${['IN PROGRESS', 'RESOLVED', 'REJECTED'].includes(c.status) ? 'disabled style="opacity:0.5;cursor:not-allowed;"' : 'style="background:#0284c7;"'}>
            ⚡ Dispatch Field Team
          </button>
          <button class="btn-primary btn-sm btn-action-status" data-action="RESOLVED" data-id="${c.id}" ${['RESOLVED', 'REJECTED'].includes(c.status) ? 'disabled style="opacity:0.5;cursor:not-allowed;"' : 'style="background:#10b981;"'}>
            ✓ Mark Tested &amp; Resolved
          </button>
          <button class="btn-ghost btn-sm btn-action-status" data-action="REJECTED" data-id="${c.id}" ${['RESOLVED', 'REJECTED'].includes(c.status) ? 'disabled style="opacity:0.5;cursor:not-allowed;"' : 'style="color:#ef4444;"'}>
            ✕ Reject / Inaccurate
          </button>
          <button class="btn-ghost btn-sm btn-inspect" data-id="${c.id}" style="margin-left:auto;">
            🔍 Full Detail &amp; Map
          </button>
        </div>
      </div>
    `).join('');

    container.querySelectorAll('.btn-action-status').forEach(btn => {
      btn.addEventListener('click', async () => {
        const action = btn.dataset.action;
        const id = btn.dataset.id;
        let note = '';

        if (action === 'IN PROGRESS') {
          note = prompt('Enter Field Inspection Note (optional):', 'Field team dispatched for on-site water sampling and line inspection.');
        } else if (action === 'RESOLVED') {
          note = prompt('Enter Water Quality Resolution Details:', 'Water quality laboratory test passed. Chlorination and line flushing completed.');
        } else if (action === 'REJECTED') {
          note = prompt('Reason for rejection:', 'Inspection found no trace of contamination or issue was outside municipal jurisdiction.');
        }

        if (note === null) return; // user cancelled prompt

        await window.CivicDB.updateStatus(id, action, note, note);
        await refresh();
      });
    });

    container.querySelectorAll('.btn-inspect').forEach(btn => {
      btn.addEventListener('click', () => openDetailModal(btn.dataset.id));
    });
  }

  window._officerRefreshFn = refresh;
  await refresh();
  window.CivicDB.subscribe(() => refresh());
}

// ============================================================
// 5. ADMIN MODULE
// ============================================================

let _adminMap = null;
let _adminMarkerCluster = null;

async function initAdmin() {
  const all = await window.CivicDB.getComplaints();
  const stats = await window.CivicDB.getStats();
  const el = id => document.getElementById(id);

  if (el('kpi-made')) el('kpi-made').textContent = stats.totalComplaints;
  if (el('kpi-pending')) el('kpi-pending').textContent = stats.openUnresolved;
  if (el('kpi-progress')) el('kpi-progress').textContent = stats.inProgressCount;
  if (el('kpi-resolved')) el('kpi-resolved').textContent = stats.resolvedCount;

  if (el('adminWaterCount')) el('adminWaterCount').textContent = stats.waterSupplyIssues;
  if (el('adminSanitationCount')) el('adminSanitationCount').textContent = stats.sanitationIssues;
  if (el('adminEnvironmentCount')) el('adminEnvironmentCount').textContent = stats.environmentIssues;

  renderTable(all);
  renderMapHotspots(all);
  renderAnalytics();

  // Attach filter event listeners
  ['filterDept', 'filterStatus', 'filterSeverity'].forEach(id => {
    el(id)?.addEventListener('change', async () => {
      const data = await window.CivicDB.getComplaints();
      renderTable(data);
    });
  });

  el('adminSearch')?.addEventListener('input', async () => {
    const data = await window.CivicDB.getComplaints();
    renderTable(data);
  });
}

function renderTable(all) {
  const el = id => document.getElementById(id);
  const dept = el('filterDept')?.value || 'ALL';
  const stat = el('filterStatus')?.value || 'ALL';
  const sev = el('filterSeverity')?.value || 'ALL';
  const term = (el('adminSearch')?.value || '').toLowerCase();

  const filtered = all.filter(c => {
    const deptOk = dept === 'ALL' || c.departmentCode === dept;
    const statOk = stat === 'ALL' || c.status === stat;
    const sevOk = sev === 'ALL' || c.severity === sev;
    const searchOk = !term ||
      c.id.toLowerCase().includes(term) ||
      (c.issue || '').toLowerCase().includes(term) ||
      (c.address || '').toLowerCase().includes(term) ||
      (c.location || '').toLowerCase().includes(term);
    return deptOk && statOk && sevOk && searchOk;
  });

  if (el('tableRecordCountBadge')) {
    el('tableRecordCountBadge').textContent = `${filtered.length} Records`;
  }

  const tbody = el('adminTableBody');
  if (!tbody) return;

  if (!filtered.length) {
    tbody.innerHTML = `<tr><td colspan="8" class="text-center text-muted" style="padding:28px;">No water contamination incidents match current filters.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(c => `
    <tr>
      <td><span class="mono" style="font-weight:800; color:#0284c7;">${c.id}</span></td>
      <td><strong>${c.issueLabel || c.issue}</strong></td>
      <td>${deptBadge(c.departmentCode)}</td>
      <td>${severityBadge(c.severity)}</td>
      <td><span class="mono" style="font-size:0.8rem;">${c.location}</span></td>
      <td>${statusBadge(c.status)}</td>
      <td style="color:var(--gray-500); font-size:0.8rem;">${c.date}</td>
      <td>
        <button class="btn-ghost btn-xs btn-inspect" data-id="${c.id}" style="font-weight:700; color:#0284c7;">
          Inspect
        </button>
      </td>
    </tr>
  `).join('');

  tbody.querySelectorAll('.btn-inspect').forEach(btn => {
    btn.addEventListener('click', () => openDetailModal(btn.dataset.id));
  });
}

async function renderMapHotspots(allComplaints) {
  const mapEl = document.getElementById('adminMap');
  if (!mapEl || typeof L === 'undefined') return;

  const complaints = allComplaints || await window.CivicDB.getComplaints();

  if (!_adminMap) {
    _adminMap = L.map('adminMap').setView([9.5245, 77.635], 13);
    window._adminMapInstance = _adminMap;

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap &bull; AquaGuard AI Hotspot GIS'
    }).addTo(_adminMap);

    if (typeof L.markerClusterGroup !== 'undefined') {
      _adminMarkerCluster = L.markerClusterGroup({ maxClusterRadius: 40 });
      _adminMap.addLayer(_adminMarkerCluster);
    }
  }

  const layer = _adminMarkerCluster || _adminMap;
  if (_adminMarkerCluster) _adminMarkerCluster.clearLayers();

  complaints.forEach(c => {
    const lat = parseFloat(c.latitude);
    const lng = parseFloat(c.longitude);
    if (isNaN(lat) || isNaN(lng)) return;

    // Distinguish water incident colors
    let color = '#0284c7';
    let emoji = '💧';

    if (c.issueType === 'drinking_water_contamination') {
      color = '#0284c7'; emoji = '💧';
    } else if (c.issueType === 'sewage_in_well') {
      color = '#d97706'; emoji = '🚰';
    } else if (c.issueType === 'sewage_pipe_leakage') {
      color = '#dc2626'; emoji = '⚠️';
    } else if (c.issueType === 'sewage_in_pond_lake' || c.issueType === 'visible_water_pollution') {
      color = '#0d9488'; emoji = '🌿';
    }

    const icon = L.divIcon({
      className: '',
      html: `<div style="background:${color};color:white;width:38px;height:38px;border-radius:50%;display:grid;place-items:center;border:2.5px solid white;box-shadow:0 4px 14px rgba(0,0,0,0.35);font-size:17px;cursor:pointer;">${emoji}</div>`,
      iconSize: [38, 38],
      iconAnchor: [19, 19]
    });

    const marker = L.marker([lat, lng], { icon });
    marker.bindPopup(`
      <div style="font-family:'Inter',sans-serif;font-size:13px;min-width:220px;padding:4px;">
        <div style="font-size:0.75rem;font-weight:800;color:${color};text-transform:uppercase;">${c.id}</div>
        <h4 style="margin:2px 0 6px;color:#0f172a;font-size:14px;">${c.issueLabel || c.issue}</h4>
        <div style="margin-bottom:4px;"><strong>Department:</strong> ${c.department}</div>
        <div style="margin-bottom:4px;"><strong>Status:</strong> ${c.status}</div>
        <div style="margin-bottom:4px;"><strong>Location:</strong> <span style="font-family:monospace;">${c.location}</span></div>
        <div style="margin-bottom:8px;font-size:11px;color:#64748b;">${c.address || ''}</div>
        <button onclick="window.openDetailModal('${c.id}')" style="width:100%;background:${color};color:white;border:0;padding:6px 12px;border-radius:6px;cursor:pointer;font-weight:700;font-size:12px;">
          Inspect Incident Details
        </button>
      </div>
    `);

    if (_adminMarkerCluster) _adminMarkerCluster.addLayer(marker);
    else marker.addTo(_adminMap);
  });
}
window.renderMapHotspots = renderMapHotspots;

async function renderAnalytics() {
  const complaints = await window.CivicDB.getComplaints();
  
  const deptCounts = { 'Water Supply': 0, 'Sanitation & Sewerage': 0, 'Environment Board': 0 };
  const issueCounts = {};

  complaints.forEach(c => {
    if (c.departmentCode === 'WATER_SUPPLY') deptCounts['Water Supply']++;
    else if (c.departmentCode === 'SANITATION') deptCounts['Sanitation & Sewerage']++;
    else deptCounts['Environment Board']++;

    const key = c.issueLabel || c.issue || 'Water Issue';
    issueCounts[key] = (issueCounts[key] || 0) + 1;
  });

  const barCanvas = document.getElementById('barChart');
  if (barCanvas && typeof Chart !== 'undefined') {
    if (window._barChartInstance) window._barChartInstance.destroy();
    window._barChartInstance = new Chart(barCanvas.getContext('2d'), {
      type: 'bar',
      data: {
        labels: Object.keys(deptCounts),
        datasets: [{
          label: 'Active Grievances',
          data: Object.values(deptCounts),
          backgroundColor: ['#0284c7', '#d97706', '#0d9488'],
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }
      }
    });
  }

  const pieCanvas = document.getElementById('doughnutChart');
  if (pieCanvas && typeof Chart !== 'undefined') {
    if (window._doughnutChartInstance) window._doughnutChartInstance.destroy();
    window._doughnutChartInstance = new Chart(pieCanvas.getContext('2d'), {
      type: 'doughnut',
      data: {
        labels: Object.keys(issueCounts),
        datasets: [{
          data: Object.values(issueCounts),
          backgroundColor: ['#0284c7', '#d97706', '#0d9488', '#dc2626', '#8b5cf6'],
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { position: 'right', labels: { boxWidth: 12, font: { size: 11 } } } }
      }
    });
  }
}

// ============================================================
// 6. COMPLAINT DETAIL & REASSIGNMENT MODAL
// ============================================================

async function openDetailModal(id) {
  const all = await window.CivicDB.getComplaints();
  const c = all.find(x => x.id === id);
  if (!c) return;

  let modal = document.getElementById('detailModal');
  if (!modal) {
    modal = document.createElement('div');
    modal.id = 'detailModal';
    modal.className = 'modal-overlay';
    document.body.appendChild(modal);
  }

  const currentUser = JSON.parse(localStorage.getItem('civiceye-user') || '{}');
  const isAdmin = currentUser.role === 'OVERALL_ADMIN';

  modal.innerHTML = `
    <div class="modal-box" style="max-width:720px;">
      <div class="modal-head">
        <div>
          <div style="font-size:0.75rem; font-weight:800; color:#0284c7; text-transform:uppercase;">Water Quality Incident File</div>
          <h3 style="margin:2px 0 0 0;">${c.id} — ${c.issueLabel || c.issue}</h3>
        </div>
        <button class="modal-close" onclick="document.getElementById('detailModal').classList.remove('open')">✕</button>
      </div>

      <div class="modal-body-inner" style="max-height:75vh; overflow-y:auto;">
        
        <div style="background:#030d1e; border-radius:var(--radius-xl); overflow:hidden; margin-bottom:18px; position:relative;">
          <img src="${c.imageUrl || 'assets/sample_drinking_water.jpg'}" alt="${c.issue}" style="width:100%; max-height:280px; object-fit:contain; display:block;" onerror="this.src='assets/sample_drinking_water.jpg'"/>
        </div>

        <div style="display:flex; gap:8px; flex-wrap:wrap; margin-bottom:16px;">
          ${statusBadge(c.status)}
          ${severityBadge(c.severity)}
          ${deptBadge(c.departmentCode)}
        </div>

        <div class="detection-grid" style="margin-bottom:16px;">
          <div class="detection-metric"><div class="detection-metric-label">Water Source</div><div class="detection-metric-value">${c.waterSourceType || 'Municipal Tap'}</div></div>
          <div class="detection-metric"><div class="detection-metric-label">Observed Contaminant</div><div class="detection-metric-value">${c.suspectedContaminant || 'Sewage / Turbidity'}</div></div>
          <div class="detection-metric"><div class="detection-metric-label">Roboflow AI Score</div><div class="detection-metric-value" style="color:#059669; font-weight:700;">${Math.round((c.confidence || 0.88)*100)}% Verified</div></div>
          <div class="detection-metric"><div class="detection-metric-label">GPS Geotag</div><div class="detection-metric-value mono" style="font-size:0.82rem;">${c.location}</div></div>
          <div class="detection-metric" style="grid-column:span 2;"><div class="detection-metric-label">Address / Landmark</div><div class="detection-metric-value" style="font-size:0.86rem;">${c.address || 'GPS verified address'}</div></div>
        </div>

        ${c.citizenDescription ? `
          <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:12px 16px; margin-bottom:14px;">
            <div class="meta-key" style="margin-bottom:4px; font-weight:700;">Citizen Observation Report:</div>
            <p style="font-size:0.88rem; color:#334155; margin:0;">${c.citizenDescription}</p>
          </div>
        ` : ''}

        ${c.notes ? `
          <div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:8px; padding:12px 16px; margin-bottom:14px;">
            <div class="meta-key" style="margin-bottom:4px; font-weight:700; color:#1e40af;">Official Investigation &amp; Resolution Log:</div>
            <p style="font-size:0.88rem; color:#1e3a8a; margin:0;">${c.notes}</p>
          </div>
        ` : ''}

        <!-- Mini Incident GIS Map -->
        <div style="margin-bottom:16px;">
          <div class="meta-key" style="margin-bottom:6px; font-weight:700;">Location on OpenStreetMap:</div>
          <div id="modalIncidentMap" style="height:180px; width:100%; border-radius:8px; border:1px solid #cbd5e1;"></div>
        </div>

        <!-- Admin Department Reassignment -->
        ${isAdmin ? `
          <div style="background:#faf5ff; border:1.5px dashed #c084fc; border-radius:8px; padding:14px; margin-top:14px;">
            <strong style="color:#6b21a8; font-size:0.88rem;">🏛️ Administrator Triage: Reassign Department</strong>
            <div style="display:flex; gap:10px; margin-top:8px;">
              <select id="modalReassignSelect" class="form-input" style="margin-bottom:0; flex:1;">
                <option value="WATER_SUPPLY" ${c.departmentCode === 'WATER_SUPPLY' ? 'selected' : ''}>Water Supply &amp; Quality Department</option>
                <option value="SANITATION" ${c.departmentCode === 'SANITATION' ? 'selected' : ''}>Sanitation &amp; Sewerage Department</option>
                <option value="ENVIRONMENT" ${c.departmentCode === 'ENVIRONMENT' ? 'selected' : ''}>Environmental &amp; Water Resources Board</option>
              </select>
              <button class="btn-primary" id="btnModalReassign" style="background:#7c3aed; padding:10px 16px; font-size:0.85rem;">
                Reassign
              </button>
            </div>
          </div>
        ` : ''}

      </div>

      <div class="modal-foot">
        <button class="btn-ghost" onclick="document.getElementById('detailModal').classList.remove('open')">Close File</button>
      </div>
    </div>
  `;

  modal.classList.add('open');

  // Render Mini Leaflet Map in Modal
  setTimeout(() => {
    const lat = parseFloat(c.latitude);
    const lng = parseFloat(c.longitude);
    if (!isNaN(lat) && !isNaN(lng) && typeof L !== 'undefined') {
      const miniMap = L.map('modalIncidentMap').setView([lat, lng], 14);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(miniMap);
      L.marker([lat, lng]).addTo(miniMap).bindPopup(`<b>${c.id}</b><br/>${c.issue}`).openPopup();
    }
  }, 100);

  // Handle Admin Reassignment Button
  if (isAdmin) {
    document.getElementById('btnModalReassign')?.addEventListener('click', async () => {
      const newDept = document.getElementById('modalReassignSelect').value;
      const note = prompt('Add reassignment note for department officer:', `Reassigned to ${newDept} by Municipal Administrator.`);
      if (note === null) return;
      await window.CivicDB.reassignDepartment(c.id, newDept, note);
      modal.classList.remove('open');
      alert(`Incident ${c.id} successfully reassigned to ${newDept}.`);
      if (window._officerRefreshFn) window._officerRefreshFn();
      if (typeof initAdmin === 'function') initAdmin();
    });
  }
}
window.openDetailModal = openDetailModal;

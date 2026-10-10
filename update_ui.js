const fs = require('fs');

const files = [
  'index.html',
  'citizen.html',
  'road-officer.html',
  'street-light-officer.html',
  'traffic-officer.html',
  'admin.html'
];

files.forEach(f => {
  let content = fs.readFileSync(f, 'utf8');
  
  // Remove API and DB buttons
  content = content.replace(/<button[^>]*id="openApiSettingsBtn"[^>]*>.*?<\/button>/g, '');
  content = content.replace(/<button[^>]*id="openDbManagerBtn"[^>]*>.*?<\/button>/g, '');
  
  // Remove Emojis
  content = content.replace(/[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/gu, '');
  
  // Remove Quick Demo Presets
  content = content.replace(/<!-- Sample Presets -->[\s\S]*?(?=<!-- GPS Card -->)/g, '');
  // Also remove the label specifically
  content = content.replace(/<div class="presets-label">[\s\S]*?<\/div>[\s\S]*?<div class="presets-row">[\s\S]*?<\/div>/g, '');
  
  // Remove Quick role switching on login page
  content = content.replace(/<div class="divider">Quick access by role<\/div>[\s\S]*?<div class="role-quick-grid">[\s\S]*?<\/div>/g, '');
  
  // Update Bottom Nav to NOT allow role switching
  if (f === 'citizen.html') {
    content = content.replace(/<div class="bottom-nav">[\s\S]*?<\/div>/g, `
  <div class="bottom-nav">
    <button type="button" class="bottom-nav-btn active" onclick="location.href='citizen.html'">Home</button>
    <button type="button" class="bottom-nav-btn" onclick="document.getElementById('myComplaintsSection').scrollIntoView({behavior:'smooth'})">My Complaints</button>
    <button type="button" class="bottom-nav-btn" onclick="logout()">Logout</button>
  </div>`);
  } else if (f === 'road-officer.html') {
    content = content.replace(/<div class="bottom-nav">[\s\S]*?<\/div>/g, `
  <div class="bottom-nav">
    <button class="bottom-nav-btn active" onclick="location.href='road-officer.html'">Dashboard</button>
    <button class="bottom-nav-btn" onclick="logout()">Logout</button>
  </div>`);
  } else if (f === 'street-light-officer.html') {
    content = content.replace(/<div class="bottom-nav">[\s\S]*?<\/div>/g, `
  <div class="bottom-nav">
    <button class="bottom-nav-btn active" onclick="location.href='street-light-officer.html'">Dashboard</button>
    <button class="bottom-nav-btn" onclick="logout()">Logout</button>
  </div>`);
  } else if (f === 'traffic-officer.html') {
    content = content.replace(/<div class="bottom-nav">[\s\S]*?<\/div>/g, `
  <div class="bottom-nav">
    <button class="bottom-nav-btn active" onclick="location.href='traffic-officer.html'">Dashboard</button>
    <button class="bottom-nav-btn" onclick="logout()">Logout</button>
  </div>`);
  } else if (f === 'admin.html') {
    content = content.replace(/<div class="bottom-nav">[\s\S]*?<\/div>/g, `
  <div class="bottom-nav">
    <button class="bottom-nav-btn active" onclick="location.href='admin.html'">Admin Center</button>
    <button class="bottom-nav-btn" onclick="logout()">Logout</button>
  </div>`);
    // Also remove the "Open X Portal ->" buttons from the admin view
    content = content.replace(/<button class="btn-secondary w-full" onclick="loginAs[^>]*>.*?<\/button>/g, '');
  }

  fs.writeFileSync(f, content);
});

// Update Script.js to use real login and logout
let scriptJs = fs.readFileSync('script.js', 'utf8');

// replace loginAs
scriptJs = scriptJs.replace(/function loginAs\(role\) \{[\s\S]*?\}/g, `function loginAs(role) {
  // Navigation disabled. User must login.
}`);

scriptJs = scriptJs.replace(/loginForm\.addEventListener\('submit', e => \{[\s\S]*?\}\);/, `loginForm.addEventListener('submit', async e => {
      e.preventDefault();
      const email = document.getElementById('email').value.trim();
      const password = document.getElementById('password').value.trim();
      try {
        const res = await fetch('/api/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password })
        });
        const data = await res.json();
        if (data.success) {
          localStorage.setItem('civiceye-role', data.user.role);
          localStorage.setItem('civiceye-user', JSON.stringify(data.user));
          const r = data.user.role;
          if (r === 'CITIZEN') window.location.href = 'citizen.html';
          else if (r === 'ROAD_OFFICER') window.location.href = 'road-officer.html';
          else if (r === 'STREET_LIGHT_OFFICER') window.location.href = 'street-light-officer.html';
          else if (r === 'TRAFFIC_OFFICER') window.location.href = 'traffic-officer.html';
          else if (r === 'OVERALL_ADMIN') window.location.href = 'admin.html';
        } else {
          alert('Login failed: ' + data.error);
        }
      } catch (err) {
        alert('Server error: ' + err.message);
      }
    });`);

scriptJs += `\n\nfunction logout() {
  localStorage.removeItem('civiceye-role');
  localStorage.removeItem('civiceye-user');
  window.location.href = 'index.html';
}\n`;

fs.writeFileSync('script.js', scriptJs);
console.log('Update script completed successfully.');

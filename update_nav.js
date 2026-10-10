const fs = require('fs');
const files = ['road-officer.html', 'street-light-officer.html', 'traffic-officer.html', 'admin.html'];

files.forEach(f => {
  let content = fs.readFileSync(f, 'utf8');
  let title = f === 'admin.html' ? 'Admin Center' : 'Dashboard';
  
  content = content.replace(/<div class="bottom-nav">[\s\S]*?<\/div>/, `<div class="bottom-nav">
    <button type="button" class="bottom-nav-btn active" onclick="location.href='${f}'">Home</button>
    <button type="button" class="bottom-nav-btn" onclick="document.getElementById('recentComplaintsSection')?.scrollIntoView({behavior:'smooth'}) || window.scrollTo({top:1000, behavior:'smooth'})">Complaints</button>
    <button type="button" class="bottom-nav-btn" onclick="logout()">Logout</button>
  </div>`);
  
  fs.writeFileSync(f, content);
});

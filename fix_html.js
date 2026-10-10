const fs = require('fs');
let content = fs.readFileSync('citizen.html', 'utf8');

const replacement = `          <div style="display:flex; flex-direction:column; gap:16px;">
            <label class="btn-primary w-full" for="cameraInput" style="cursor:pointer; display:flex; align-items:center; gap:16px; padding:16px;">
              <input type="file" id="cameraInput" accept="image/*" capture="environment" class="hidden" onchange="handleImageSelection(event)" />
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>
              <div style="text-align:left;">
                <div style="font-size:1.15rem; font-weight:700;">Open Camera</div>
                <div style="font-size:0.85rem; opacity:0.8;">Capture live photo</div>
              </div>
            </label>

            <label class="btn-secondary w-full" for="galleryInput" style="cursor:pointer; display:flex; align-items:center; gap:16px; padding:16px;">
              <input type="file" id="galleryInput" accept="image/*" class="hidden" onchange="handleImageSelection(event)" />
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
              <div style="text-align:left;">
                <div style="font-size:1.15rem; font-weight:700;">Upload from Gallery</div>
                <div style="font-size:0.85rem; opacity:0.8;">Select an existing photo</div>
              </div>
            </label>
          </div>`;

content = content.replace(/<div class="action-grid">[\s\S]*?<\/div>\s*<\/div>/, replacement + '\n\n          </div>');
fs.writeFileSync('citizen.html', content);

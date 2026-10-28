const fs = require('fs');
const https = require('https');

const os = require('os');
const path = require('path');

// 1. Read tokens from configstore
function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  return config.tokens.access_token;
}

// 2. Parse presets from image_preset.dart
function parsePresets() {
  const content = fs.readFileSync('lib/features/chat/domain/entities/image_preset.dart', 'utf8');
  
  // Split by ImagePreset(
  const parts = content.split('ImagePreset(').slice(1);
  const presets = [];

  for (const part of parts) {
    const idMatch = part.match(/id:\s*['"]([^'"]+)['"]/);
    const titleMatch = part.match(/title:\s*(?:"([^"]+)"|'([^']+)')/);
    const imagePathMatch = part.match(/imagePath:\s*['"]([^'"]+)['"]/);
    const promptMatch = part.match(/prompt:\s*(?:'''|')([\s\S]*?)(?:'''|'),\s*\)/);

    if (idMatch && titleMatch && imagePathMatch && promptMatch) {
      presets.push({
        id: idMatch[1],
        title: titleMatch[1] || titleMatch[2],
        imagePath: imagePathMatch[1],
        prompt: promptMatch[1].trim()
      });
    }
  }

  return presets;
}

function writeDocument(projectId, preset, order, token) {
  return new Promise((resolve, reject) => {
    const docId = preset.id;
    const path = `/v1/projects/${projectId}/databases/(default)/documents/image_presets/${docId}?updateMask.fieldPaths=id&updateMask.fieldPaths=title&updateMask.fieldPaths=imagePath&updateMask.fieldPaths=prompt&updateMask.fieldPaths=order&updateMask.fieldPaths=updatedAt`;
    
    const payload = JSON.stringify({
      fields: {
        id: { stringValue: preset.id },
        title: { stringValue: preset.title },
        imagePath: { stringValue: preset.imagePath },
        prompt: { stringValue: preset.prompt },
        order: { integerValue: String(order) },
        updatedAt: { stringValue: new Date().toISOString() }
      }
    });

    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: path,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function main() {
  const token = getAccessToken();
  const presets = parsePresets();
  const projectId = 'paceai-4733a';

  console.log(`Found ${presets.length} presets to upload to Firestore project: ${projectId}...`);

  for (let i = 0; i < presets.length; i++) {
    const preset = presets[i];
    const order = i + 1;
    process.stdout.write(`[${order}/${presets.length}] Uploading '${preset.id}' (${preset.title})... `);
    try {
      await writeDocument(projectId, preset, order, token);
      console.log('✓ Success');
    } catch (err) {
      console.log('✗ Failed: ' + err.message);
    }
  }

  console.log('\nAll presets processed!');
}

main().catch(console.error);

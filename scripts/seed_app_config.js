const fs = require('fs');
const https = require('https');
const os = require('os');
const path = require('path');

function getFreshAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const refreshToken = config.tokens.refresh_token;

  return new Promise((resolve, reject) => {
    const postData = new URLSearchParams({
      client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
      client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
      grant_type: 'refresh_token',
      refresh_token: refreshToken
    }).toString();

    const req = https.request({
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.access_token) {
            resolve(parsed.access_token);
          } else {
            reject(new Error(`Failed to refresh token: ${data}`));
          }
        } catch (e) {
          reject(e);
        }
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function writeVersionControl(projectId, token, config) {
  return new Promise((resolve, reject) => {
    const reqPath = `/v1/projects/${projectId}/databases/(default)/documents/app_config/version_control?updateMask.fieldPaths=min_supported_build&updateMask.fieldPaths=latest_build&updateMask.fieldPaths=force_update&updateMask.fieldPaths=title&updateMask.fieldPaths=message&updateMask.fieldPaths=play_store_url&updateMask.fieldPaths=updated_at`;

    const payload = JSON.stringify({
      fields: {
        min_supported_build: { integerValue: String(config.min_supported_build) },
        latest_build: { integerValue: String(config.latest_build) },
        force_update: { booleanValue: config.force_update },
        title: { stringValue: config.title },
        message: { stringValue: config.message },
        play_store_url: { stringValue: config.play_store_url },
        updated_at: { stringValue: new Date().toISOString() }
      }
    });

    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: reqPath,
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
  console.log('1. Refreshing Google OAuth token from Firebase CLI...');
  const token = await getFreshAccessToken();
  console.log('✓ Token refreshed successfully');

  const projectId = 'paceai-4733a';
  const config = {
    min_supported_build: 24,
    latest_build: 24,
    force_update: true,
    title: 'Update Slipe AI',
    message: 'A critical update is available with improved AI photo & video generation, ad optimizations, and performance improvements. Please update to continue.',
    play_store_url: 'https://play.google.com/store/apps/details?id=com.paceai.paceai'
  };

  console.log(`2. Seeding app_config/version_control in Firestore (${projectId})...`);
  console.log('   Config:', JSON.stringify(config, null, 2));

  const result = await writeVersionControl(projectId, token, config);
  console.log('✓ SUCCESS: app_config/version_control document is live in Firestore!');
  console.log('  Document name:', result.name);
}

main().catch(err => {
  console.error('✗ ERROR:', err.message);
  process.exit(1);
});

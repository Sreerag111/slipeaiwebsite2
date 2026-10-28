const fs = require('fs');
const https = require('https');

const os = require('os');
const path = require('path');

function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  return config.tokens.access_token;
}

const newOrder = [
  { order: 1, id: 'nineties_camera', title: "90's Camera" },
  { order: 2, id: 'golden_effect', title: 'Golden Effect' },
  { order: 3, id: 'three_d_figure', title: '3D Figure' },
  { order: 4, id: 'me_and_my_dog', title: 'Me & My Dog' },
  { order: 5, id: 'aesthetic_scrapbook', title: 'Aesthetic Scrapbook' },
  { order: 6, id: 'y2k_style', title: 'Y2K Style' },
  { order: 7, id: 'twin_me', title: 'Twin Me' },
  { order: 8, id: 'cowboy', title: 'Cowboy' },
  { order: 9, id: 'barbie_me', title: 'Barbie Me' },
  { order: 10, id: 'mafia', title: 'Mafia' },
  { order: 11, id: 'gangster_look', title: 'Gangster' },
  { order: 12, id: 'ai_photoshoot', title: 'Photoshoot' },
  { order: 13, id: 'aesthetic_collage', title: 'Aesthetic Collage' },
  { order: 14, id: 'cartoon_look', title: 'Cartoon Look' },
  { order: 15, id: 'polaroid_frame', title: 'Polaroid Frame' },
  { order: 16, id: 'hip_hop', title: 'Hip-Hop' },
  { order: 17, id: 'me_with_my_bike', title: 'Me & My Bike' },
  { order: 18, id: 'personality_sketch', title: 'Personality Sketch' },
  { order: 19, id: 'korean_streetwear', title: 'Korean Streetwear' },
  { order: 20, id: 'me_and_my_toy', title: 'Me & My Toy' },
  { order: 21, id: 'black_and_white', title: 'Black & White' }
];

function updateOrder(projectId, item, token) {
  return new Promise((resolve, reject) => {
    const docId = item.id;
    const path = `/v1/projects/${projectId}/databases/(default)/documents/image_presets/${docId}?updateMask.fieldPaths=order`;

    const payload = JSON.stringify({
      fields: {
        order: { integerValue: String(item.order) }
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
  const projectId = 'paceai-4733a';

  console.log(`Updating order for all 21 presets in Firestore (${projectId})...`);

  for (const item of newOrder) {
    process.stdout.write(`Setting order ${item.order} for '${item.id}' (${item.title})... `);
    try {
      await updateOrder(projectId, item, token);
      console.log('✓ Success');
    } catch (err) {
      console.log('✗ Failed: ' + err.message);
    }
  }

  console.log('\nAll preset orders updated in Firestore!');
}

main().catch(console.error);

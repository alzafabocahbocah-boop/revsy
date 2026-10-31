const { chromium } = require('playwright');

// ===== CONFIG =====
const WORKER_URL = 'https://dry-glitter-63e4.petagee5.workers.dev';
const WORKER_KUNCI = 'nfSUwzy6aXTFF0a546iQ2tizIVBeTF3T2Z1Xx0rb';
const POLL_INTERVAL = 3000;
// ==================

const headers = { 'X-Kunci': WORKER_KUNCI, 'Content-Type': 'application/json' };

const aktif = new Set(); // ID yang sedang diproses (reset kalau server restart)

async function scanKeyFromDOM(page) {
  return page.evaluate(() => {
    const body = document.body.innerText || document.body.textContent || '';
    const m1 = body.match(/FREE_[a-f0-9]{32}/i);
    if (m1) return m1[0];
    const inputs = document.querySelectorAll('input, textarea');
    for (const el of inputs) {
      const val = el.value || '';
      const m2 = val.match(/FREE_[a-f0-9]{32}/i);
      if (m2) return m2[0];
    }
    return null;
  });
}

async function processPlato(platoUrl) {
  const browser = await chromium.launch({ headless: false });
  try {
    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    });
    const page = await context.newPage();

    await page.goto(platoUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
    console.log('[*] Page loaded, tunggu 5 detik...');
    await page.waitForTimeout(5000);

    const keyBefore = await scanKeyFromDOM(page);
    if (keyBefore) {
      console.log('[!!!] KEY SUDAH ADA DI DOM:', keyBefore);
      return { type: 'key', value: keyBefore };
    }

    const btnInfo = await page.evaluate(() => {
      const buttons = document.querySelectorAll('button');
      return Array.from(buttons).map(b => (b.innerText || b.textContent || '').trim()).join(' | ');
    });
    console.log('[*] Buttons:', btnInfo || '(none)');

    const pageText = await page.evaluate(() => document.body.innerText || '');
    console.log('[*] Page text (200 char):', pageText.slice(0, 200).replace(/\n/g, ' '));

    let result = { type: null, value: null };

    console.log('[*] Klik Continue, tunggu navigasi...');
    const navPromise = page.waitForNavigation({ timeout: 15000, waitUntil: 'domcontentloaded' });

    await page.evaluate(() => {
      const buttons = document.querySelectorAll('button');
      for (const btn of buttons) {
        const txt = (btn.innerText || btn.textContent || '').trim().toLowerCase();
        if (txt === 'continue') { btn.click(); return; }
      }
      if (buttons.length > 0) buttons[buttons.length - 1].click();
    });

    try {
      await navPromise;
      await page.waitForTimeout(2000);
      const currentUrl = page.url();
      console.log('[*] Navigasi ke:', currentUrl.slice(0, 120));

      if (currentUrl.includes('lootlabs.gg')) {
        result = { type: 'url', value: currentUrl };
      } else if (currentUrl.includes('platorelay.com')) {
        result = { type: 'url', value: currentUrl };
      } else {
        await page.waitForTimeout(3000);
        const keyNav = await scanKeyFromDOM(page);
        if (keyNav) result = { type: 'key', value: keyNav };
      }
    } catch (e) {
      console.log('[*] Tidak ada navigasi, scan DOM...');
      await page.waitForTimeout(5000);
      const currentUrl = page.url();
      console.log('[*] Current URL:', currentUrl.slice(0, 120));
      const keyFallback = await scanKeyFromDOM(page);
      if (keyFallback) result = { type: 'key', value: keyFallback };
      else console.log('[!] Key tidak ditemukan');
    }

    return result;
  } finally {
    await browser.close();
  }
}

async function bypassLootlabs(lootlabsUrl) {
  const bypassUrl = 'https://api.bypass.vip/premium/bypass?url=' + encodeURIComponent(lootlabsUrl);
  const res = await fetch(bypassUrl, {
    headers: { 'x-api-key': '621eeee7-973c-4789-a605-138214d87873' }
  });
  const data = await res.json();
  console.log('[bypass.vip]', JSON.stringify(data).slice(0, 200));
  return data.result || data.destination || null;
}

async function getKey(platoUrl, depth = 0) {
  if (depth > 5) return null;
  console.log('\n[*] Checkpoint', depth + 1, '...');

  const result = await processPlato(platoUrl);
  if (result.type === 'key') return result.value;

  if (result.type === 'url') {
    const nextUrl = result.value;
    if (nextUrl.includes('lootlabs.gg')) {
      console.log('[*] Bypass lootlabs...');
      const bypassed = await bypassLootlabs(nextUrl);
      if (!bypassed) return null;
      if (bypassed.includes('platorelay.com')) return getKey(bypassed, depth + 1);
      const m = bypassed.match(/FREE_[a-f0-9]{32}/i);
      if (m) return m[0];
      return bypassed;
    }
    if (nextUrl.includes('platorelay.com')) return getKey(nextUrl, depth + 1);
    return nextUrl;
  }

  return null;
}

async function kirimHasil(id, key) {
  try {
    await fetch(WORKER_URL + '/delta-hasil', {
      method: 'POST',
      headers,
      body: JSON.stringify({ id, key })
    });
    console.log('[+] Hasil terkirim, id:', id, '| key:', key ? key.slice(0, 20) + '...' : 'null');
  } catch (e) {
    console.error('[!] Gagal kirim hasil:', e.message);
  }
}

async function hapusAntrian(id) {
  try {
    await fetch(WORKER_URL + '/delta-antri?id=' + encodeURIComponent(id), {
      method: 'DELETE', headers
    });
  } catch (e) {}
}

// Tiap request spawn browser sendiri, tidak ganggu yang lain
function spawnProses(item) {
  aktif.add(item.id);
  console.log('\n[+] SPAWN browser untuk id:', item.id);
  console.log('[+] Link:', item.link.slice(0, 70));
  console.log('[+] Aktif sekarang:', aktif.size, 'browser');

  getKey(item.link)
    .then(async key => {
      console.log('[+] KEY dapat! id:', item.id, '| key:', key);
      await hapusAntrian(item.id);
      await kirimHasil(item.id, key);
    })
    .catch(async e => {
      console.error('[!] Error id:', item.id, '|', e.message);
      await hapusAntrian(item.id);
      await kirimHasil(item.id, null);
    })
    .finally(() => {
      aktif.delete(item.id);
      console.log('[+] Browser tutup, id:', item.id, '| Sisa aktif:', aktif.size);
    });
}

async function pollDanProses() {
  try {
    const res = await fetch(WORKER_URL + '/delta-antri', { headers });
    const data = await res.json();
    const items = data.items || [];

    // Spawn browser untuk setiap item baru yang belum diproses
    for (const item of items) {
      if (!aktif.has(item.id)) {
        spawnProses(item);
      }
    }
  } catch (e) {
    console.error('[!] Poll error:', e.message);
  }
}

console.log('[+] PC Delta Key Processor jalan');
console.log('[+] Worker:', WORKER_URL);
console.log('[+] Polling setiap', POLL_INTERVAL / 1000, 'detik...');
console.log('[+] Mode: tiap request baru langsung spawn browser sendiri');

pollDanProses();
setInterval(pollDanProses, POLL_INTERVAL);

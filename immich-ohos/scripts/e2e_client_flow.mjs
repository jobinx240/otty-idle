#!/usr/bin/env node
/**
 * End-to-end Immich client flow against a live server (default: public demo).
 * Mirrors the HarmonyOS app sequence: ping → login → me → timeline → thumb →
 * albums → search → optional upload of a tiny JPEG.
 *
 * On a fresh self-hosted server (empty library), upload runs first so timeline /
 * album / search assertions have data. Use IMMICH_BOOTSTRAP=1 to create the
 * first admin when no users exist yet.
 *
 * Env: IMMICH_URL, IMMICH_EMAIL, IMMICH_PASSWORD, SKIP_UPLOAD=1, IMMICH_BOOTSTRAP=1,
 *      IMMICH_NAME, E2E_JPEG
 */
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';

const base = (process.env.IMMICH_URL || 'https://demo.immich.app').replace(/\/$/, '');
const api = `${base}/api`;
const email = process.env.IMMICH_EMAIL || 'demo@immich.app';
const password = process.env.IMMICH_PASSWORD || 'demo';
const name = process.env.IMMICH_NAME || 'Admin';
const skipUpload = process.env.SKIP_UPLOAD === '1';
const bootstrap = process.env.IMMICH_BOOTSTRAP === '1';
const jpegPath = process.env.E2E_JPEG || '/tmp/e2e.jpg';

async function req(method, path, { token, body, raw } = {}) {
  const headers = { Accept: 'application/json' };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
    headers['x-immich-user-token'] = token;
  }
  let payload;
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }
  const res = await fetch(`${api}${path}`, { method, headers, body: payload });
  if (raw) {
    return { status: res.status, buf: Buffer.from(await res.arrayBuffer()), ctype: res.headers.get('content-type') };
  }
  const text = await res.text();
  let data = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      throw new Error(`${method} ${path} non-JSON ${res.status}: ${text.slice(0, 200)}`);
    }
  }
  return { status: res.status, data };
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

async function uploadAsset(token) {
  const jpeg = readFileSync(jpegPath);
  const checksum = createHash('sha1').update(jpeg).digest('base64');
  const form = new FormData();
  form.append('assetData', new Blob([jpeg], { type: 'image/jpeg' }), 'e2e.jpg');
  form.append('fileCreatedAt', new Date().toISOString());
  form.append('fileModifiedAt', new Date().toISOString());
  form.append('filename', 'e2e.jpg');
  form.append('deviceAssetId', `ohos-e2e-${Date.now()}`);
  form.append('deviceId', 'harmonyos-e2e');
  form.append('isFavorite', 'false');
  form.append('duration', '0');
  const up = await fetch(`${api}/assets`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'x-immich-user-token': token,
      'x-immich-checksum': checksum
    },
    body: form
  });
  const text = await up.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    throw new Error(`upload non-JSON ${up.status}: ${text.slice(0, 300)}`);
  }
  assert(up.status === 200 || up.status === 201, `upload ${up.status} ${text}`);
  return { status: data.status, id: data.id, http: up.status };
}

async function waitForBuckets(token, attempts = 20) {
  for (let i = 0; i < attempts; i++) {
    const buckets = await req('GET', '/timeline/buckets', { token });
    if (buckets.status === 200 && Array.isArray(buckets.data) && buckets.data.length > 0) {
      return buckets;
    }
    await new Promise((r) => setTimeout(r, 500));
  }
  return req('GET', '/timeline/buckets', { token });
}

async function main() {
  const steps = [];

  const ping = await req('GET', '/server/ping');
  assert(ping.status === 200 && ping.data?.res === 'pong', `ping ${ping.status}`);
  steps.push('ping');

  if (bootstrap) {
    const signup = await req('POST', '/auth/admin-sign-up', {
      body: { email, password, name }
    });
    if (signup.status === 201) {
      steps.push('admin-sign-up');
    } else if (signup.status === 400 || signup.status === 403) {
      steps.push(`admin-sign-up-skip(${signup.status})`);
    } else {
      throw new Error(`admin-sign-up ${signup.status}`);
    }
  }

  const login = await req('POST', '/auth/login', { body: { email, password } });
  assert(login.status === 201 && login.data?.accessToken, `login ${login.status}`);
  const token = login.data.accessToken;
  steps.push('login');

  const me = await req('GET', '/users/me', { token });
  assert(me.status === 200, `me ${me.status}`);
  steps.push('me');

  let upload = null;
  let earlyBuckets = await req('GET', '/timeline/buckets', { token });
  const libraryEmpty = earlyBuckets.status === 200 && (!earlyBuckets.data || earlyBuckets.data.length === 0);

  if (!skipUpload && libraryEmpty) {
    upload = await uploadAsset(token);
    steps.push(`upload(${upload.status})`);
    earlyBuckets = await waitForBuckets(token);
  }

  assert(earlyBuckets.status === 200 && earlyBuckets.data.length > 0, 'buckets empty');
  const tb = earlyBuckets.data[0].timeBucket;
  const bucket = await req('GET', `/timeline/bucket?timeBucket=${encodeURIComponent(tb)}`, { token });
  assert((bucket.data?.id || []).length > 0, 'bucket empty');
  const ids = bucket.data.id;
  steps.push(`timeline(${ids.length})`);

  // Prefer an asset that already has a thumbhash; newly uploaded files may 404 until processed.
  let assetId = ids[0];
  const hashes = bucket.data.thumbhash || [];
  for (let i = 0; i < ids.length; i++) {
    if (hashes[i]) {
      assetId = ids[i];
      break;
    }
  }

  let thumb = null;
  for (let i = 0; i < 40; i++) {
    thumb = await req('GET', `/assets/${assetId}/thumbnail?size=thumbnail`, { token, raw: true });
    if (thumb.status === 200 && thumb.buf.length > 100) {
      break;
    }
    // Fall through other ids if the chosen one is still processing.
    if (thumb.status === 404 && i % 5 === 4) {
      const next = ids.find((id) => id !== assetId);
      if (next) {
        assetId = next;
      }
    }
    await new Promise((r) => setTimeout(r, 500));
  }
  assert(thumb && thumb.status === 200 && thumb.buf.length > 100, `thumb ${thumb?.status}`);
  steps.push(`thumb(${thumb.buf.length})`);

  // Ensure at least one album with assets (create if needed)
  let albums = await req('GET', '/albums', { token });
  assert(albums.status === 200, 'albums failed');
  let album = (albums.data || []).filter((a) => a.assetCount > 0).sort((a, b) => b.assetCount - a.assetCount)[0];
  if (!album) {
    const created = await req('POST', '/albums', { token, body: { albumName: 'E2E Album' } });
    assert(created.status === 201 && created.data?.id, `create album ${created.status}`);
    const add = await req('PUT', `/albums/${created.data.id}/assets`, {
      token,
      body: { ids: [assetId] }
    });
    assert(add.status === 200, `add album assets ${add.status}`);
    albums = await req('GET', '/albums', { token });
    album = (albums.data || []).find((a) => a.id === created.data.id);
    steps.push('album-create');
  }
  assert(album, 'no album');
  const ab = await req('GET', `/timeline/buckets?albumId=${album.id}`, { token });
  assert(ab.data.length > 0, 'album buckets empty');
  const abd = await req(
    'GET',
    `/timeline/bucket?albumId=${album.id}&timeBucket=${encodeURIComponent(ab.data[0].timeBucket)}`,
    { token }
  );
  assert((abd.data?.id || []).length > 0, 'album assets empty');
  steps.push(`album(${abd.data.id.length})`);

  const search = await req('POST', '/search/metadata', { token, body: { q: 'e2e', size: 5 } });
  assert((search.data?.assets?.items || []).length > 0, 'search empty');
  steps.push(`search(${search.data.assets.items.length})`);

  if (!skipUpload && !upload) {
    upload = await uploadAsset(token);
    steps.push(`upload(${upload.status})`);
  }

  console.log(JSON.stringify({ ok: true, base, user: me.data.email, steps, upload }, null, 2));
}

main().catch((e) => {
  console.error('E2E FAIL', e.message || e);
  process.exit(1);
});

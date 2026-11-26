#!/usr/bin/env node
/**
 * Smoke-test Immich HTTP APIs used by the HarmonyOS client.
 * Default target: public demo. Override with IMMICH_URL / IMMICH_EMAIL / IMMICH_PASSWORD.
 */
const base = (process.env.IMMICH_URL || 'https://demo.immich.app').replace(/\/$/, '');
const api = `${base}/api`;
const email = process.env.IMMICH_EMAIL || 'demo@immich.app';
const password = process.env.IMMICH_PASSWORD || 'demo';

async function req(method, path, { token, body, raw } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }
  if (token) {
    headers.Authorization = `Bearer ${token}`;
    headers['x-immich-user-token'] = token;
  }
  const res = await fetch(`${api}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined
  });
  if (raw) {
    const buf = Buffer.from(await res.arrayBuffer());
    return { status: res.status, buf };
  }
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  return { status: res.status, data };
}

function assert(cond, msg) {
  if (!cond) {
    throw new Error(msg);
  }
}

async function main() {
  const ping = await req('GET', '/server/ping');
  assert(ping.status === 200 && ping.data?.res === 'pong', `ping failed: ${ping.status}`);

  const login = await req('POST', '/auth/login', { body: { email, password } });
  assert(login.status === 201 && login.data?.accessToken, `login failed: ${login.status}`);
  const token = login.data.accessToken;

  const me = await req('GET', '/users/me', { token });
  assert(me.status === 200 && me.data?.email, `me failed: ${me.status}`);

  const buckets = await req('GET', '/timeline/buckets', { token });
  assert(buckets.status === 200 && Array.isArray(buckets.data) && buckets.data.length > 0, 'no buckets');
  const tb = buckets.data[0].timeBucket;
  const bucket = await req('GET', `/timeline/bucket?timeBucket=${encodeURIComponent(tb)}`, { token });
  assert(bucket.status === 200 && Array.isArray(bucket.data?.id) && bucket.data.id.length > 0, 'empty bucket');
  const assetId = bucket.data.id[0];

  const thumb = await req('GET', `/assets/${assetId}/thumbnail?size=thumbnail`, { token, raw: true });
  assert(thumb.status === 200 && thumb.buf.length > 100, `thumb failed: ${thumb.status}`);

  const albums = await req('GET', '/albums', { token });
  assert(albums.status === 200 && Array.isArray(albums.data), 'albums failed');
  const withAssets = albums.data.filter((a) => (a.assetCount || 0) > 0).sort((a, b) => b.assetCount - a.assetCount);
  assert(withAssets.length > 0, 'no albums with assets on demo');
  const albumId = withAssets[0].id;
  const albumBuckets = await req('GET', `/timeline/buckets?albumId=${encodeURIComponent(albumId)}`, { token });
  assert(albumBuckets.status === 200 && albumBuckets.data.length > 0, 'album buckets empty');
  const atb = albumBuckets.data[0].timeBucket;
  const albumBucket = await req(
    'GET',
    `/timeline/bucket?albumId=${encodeURIComponent(albumId)}&timeBucket=${encodeURIComponent(atb)}`,
    { token }
  );
  assert(albumBucket.status === 200 && (albumBucket.data?.id || []).length > 0, 'album bucket empty');

  const search = await req('POST', '/search/metadata', { token, body: { q: 'a', size: 5 } });
  assert(search.status === 200 && Array.isArray(search.data?.assets?.items), 'search failed');

  console.log(
    JSON.stringify(
      {
        ok: true,
        base,
        user: me.data.email,
        buckets: buckets.data.length,
        firstBucketAssets: bucket.data.id.length,
        thumbBytes: thumb.buf.length,
        albums: albums.data.length,
        albumSampleAssets: albumBucket.data.id.length,
        searchHits: search.data.assets.items.length
      },
      null,
      2
    )
  );
}

main().catch((e) => {
  console.error('SMOKE FAIL', e.message || e);
  process.exit(1);
});

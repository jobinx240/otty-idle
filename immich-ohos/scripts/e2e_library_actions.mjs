#!/usr/bin/env node
/**
 * Smoke: archive / trash restore / create album / add assets / original download.
 * Usage: IMMICH_URL=http://127.0.0.1:2283 node scripts/e2e_library_actions.mjs
 */
const base = `${(process.env.IMMICH_URL || 'http://127.0.0.1:2283').replace(/\/$/, '')}/api`;
const email = process.env.IMMICH_EMAIL || 'admin@local.test';
const password = process.env.IMMICH_PASSWORD || 'Admin12345';

async function login() {
  let res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  if (res.status !== 201) {
    await fetch(`${base}/auth/admin-sign-up`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, name: 'Admin' })
    });
    res = await fetch(`${base}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
  }
  if (res.status !== 201) {
    throw new Error(`login failed: ${res.status}`);
  }
  return (await res.json()).accessToken;
}

async function firstAssetId(headers) {
  const buckets = await (await fetch(`${base}/timeline/buckets`, { headers })).json();
  if (!buckets.length) {
    throw new Error('no timeline buckets');
  }
  const bucket = await (
    await fetch(`${base}/timeline/bucket?timeBucket=${encodeURIComponent(buckets[0].timeBucket)}`, {
      headers
    })
  ).json();
  if (!bucket.id?.length) {
    throw new Error('empty bucket');
  }
  return bucket.id[0];
}

async function main() {
  const token = await login();
  const headers = {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
  const id = await firstAssetId(headers);

  const archive = await fetch(`${base}/assets/${id}`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({ visibility: 'archive' })
  });
  const archiveBody = await archive.json();
  if (archive.status !== 200 || archiveBody.visibility !== 'archive') {
    throw new Error(`archive failed: ${archive.status}`);
  }
  const archiveBuckets = await (
    await fetch(`${base}/timeline/buckets?visibility=archive`, { headers })
  ).json();
  if (!Array.isArray(archiveBuckets) || archiveBuckets.length < 1) {
    throw new Error('archive buckets empty');
  }

  const unarchive = await fetch(`${base}/assets/${id}`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({ visibility: 'timeline' })
  });
  if (unarchive.status !== 200) {
    throw new Error(`unarchive failed: ${unarchive.status}`);
  }

  const trash = await fetch(`${base}/assets`, {
    method: 'DELETE',
    headers,
    body: JSON.stringify({ ids: [id], force: false })
  });
  if (trash.status < 200 || trash.status >= 300) {
    throw new Error(`trash failed: ${trash.status}`);
  }
  const trashBuckets = await (
    await fetch(`${base}/timeline/buckets?isTrashed=true`, { headers })
  ).json();
  if (!Array.isArray(trashBuckets) || trashBuckets.length < 1) {
    throw new Error('trash buckets empty');
  }
  const restore = await fetch(`${base}/trash/restore/assets`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ ids: [id] })
  });
  if (restore.status !== 200) {
    throw new Error(`restore failed: ${restore.status}`);
  }

  const albumName = `OHOS E2E ${Date.now()}`;
  const create = await fetch(`${base}/albums`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ albumName, assetIds: [id] })
  });
  const album = await create.json();
  if (create.status !== 201 || !album.id) {
    throw new Error(`create album failed: ${create.status}`);
  }
  const add = await fetch(`${base}/albums/${album.id}/assets`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({ ids: [id] })
  });
  if (add.status !== 200) {
    throw new Error(`add assets failed: ${add.status}`);
  }

  const original = await fetch(`${base}/assets/${id}/original`, { headers });
  const bytes = await original.arrayBuffer();
  if (original.status !== 200 || bytes.byteLength < 1) {
    throw new Error(`original download failed: ${original.status}`);
  }

  console.log(
    JSON.stringify(
      {
        ok: true,
        id,
        albumId: album.id,
        albumName,
        originalBytes: bytes.byteLength,
        archiveBuckets: archiveBuckets.length,
        trashBuckets: trashBuckets.length
      },
      null,
      2
    )
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

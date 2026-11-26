#!/usr/bin/env node
/**
 * Smoke: version gate inputs, tags, shared links, album delete.
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
    throw new Error(`login ${res.status}`);
  }
  return (await res.json()).accessToken;
}

async function firstAssetId(headers) {
  const buckets = await (await fetch(`${base}/timeline/buckets`, { headers })).json();
  const bucket = await (
    await fetch(`${base}/timeline/bucket?timeBucket=${encodeURIComponent(buckets[0].timeBucket)}`, {
      headers
    })
  ).json();
  return bucket.id[0];
}

async function main() {
  const ver = await (await fetch(`${base}/server/version`)).json();
  if (typeof ver.major !== 'number') {
    throw new Error('version missing major');
  }

  const token = await login();
  const headers = {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
  const id = await firstAssetId(headers);

  const tagName = `ohos-tag-${Date.now()}`;
  const tagRes = await fetch(`${base}/tags`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ name: tagName })
  });
  const tag = await tagRes.json();
  if (tagRes.status !== 201 || !tag.id) {
    throw new Error(`create tag ${tagRes.status}`);
  }
  const attach = await fetch(`${base}/tags/${tag.id}/assets`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({ ids: [id] })
  });
  if (attach.status !== 200) {
    throw new Error(`tag assets ${attach.status}`);
  }
  const tagBuckets = await (
    await fetch(`${base}/timeline/buckets?tagId=${tag.id}`, { headers })
  ).json();
  if (!tagBuckets.length) {
    throw new Error('tag buckets empty');
  }

  const share = await fetch(`${base}/shared-links`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      type: 'INDIVIDUAL',
      assetIds: [id],
      allowDownload: true,
      allowUpload: false,
      showMetadata: true
    })
  });
  const link = await share.json();
  if (share.status !== 201 || !link.key) {
    throw new Error(`shared link ${share.status}`);
  }
  const del = await fetch(`${base}/shared-links/${link.id}`, {
    method: 'DELETE',
    headers
  });
  if (del.status < 200 || del.status >= 300) {
    throw new Error(`delete shared ${del.status}`);
  }

  const album = await (
    await fetch(`${base}/albums`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ albumName: `tmp-${Date.now()}` })
    })
  ).json();
  const delAlbum = await fetch(`${base}/albums/${album.id}`, {
    method: 'DELETE',
    headers
  });
  if (delAlbum.status < 200 || delAlbum.status >= 300) {
    throw new Error(`delete album ${delAlbum.status}`);
  }

  console.log(
    JSON.stringify(
      {
        ok: true,
        serverVersion: `${ver.major}.${ver.minor}.${ver.patch}`,
        tagId: tag.id,
        tagBuckets: tagBuckets.length,
        sharedKey: link.key
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

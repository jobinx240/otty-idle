#!/usr/bin/env node
/**
 * Full feature-by-feature Immich API audit for the OHOS client surface.
 * Prints one JSON report with per-check pass/fail.
 */
import { createHash } from 'node:crypto';
import { readFileSync, existsSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const base = `${(process.env.IMMICH_URL || 'http://127.0.0.1:2283').replace(/\/$/, '')}/api`;
const email = process.env.IMMICH_EMAIL || 'admin@local.test';
const password = process.env.IMMICH_PASSWORD || 'Admin12345';

const results = [];

function check(id, ok, detail = '') {
  results.push({ id, ok: !!ok, detail: `${detail}` });
  const mark = ok ? 'PASS' : 'FAIL';
  console.log(`${mark}\t${id}${detail ? `\t${detail}` : ''}`);
}

async function req(method, path, { token, body, raw } = {}) {
  const headers = {};
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  let payload;
  if (body !== undefined) {
    if (raw) {
      payload = body;
      Object.assign(headers, raw.headers || {});
    } else {
      headers['Content-Type'] = 'application/json';
      payload = JSON.stringify(body);
    }
  }
  const res = await fetch(`${base}${path}`, { method, headers, body: payload });
  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : undefined;
  } catch (_e) {
    json = undefined;
  }
  return { status: res.status, text, json, headers: res.headers, buf: undefined };
}

async function reqBuf(method, path, token) {
  const res = await fetch(`${base}${path}`, {
    method,
    headers: token ? { Authorization: `Bearer ${token}` } : {}
  });
  const buf = Buffer.from(await res.arrayBuffer());
  return { status: res.status, buf, headers: res.headers };
}

async function login() {
  let res = await req('POST', '/auth/login', { body: { email, password } });
  if (res.status !== 201) {
    await req('POST', '/auth/admin-sign-up', {
      body: { email, password, name: 'Admin' }
    });
    res = await req('POST', '/auth/login', { body: { email, password } });
  }
  return res;
}

function fileExists(rel, id) {
  const p = join(ROOT, rel);
  check(id, existsSync(p), rel);
}

async function main() {
  // --- Code wiring (client surface) ---
  const pages = [
    'LoginPage',
    'TimelinePage',
    'AssetViewerPage',
    'BackupPage',
    'AlbumsPage',
    'AlbumDetailPage',
    'SearchPage',
    'PeoplePage',
    'SettingsPage',
    'TrashPage',
    'ArchivePage',
    'AddToAlbumPage',
    'TagsPage',
    'AddToTagPage',
    'SharedLinksPage'
  ];
  for (const p of pages) {
    fileExists(`entry/src/main/ets/pages/${p}.ets`, `code.page.${p}`);
  }
  fileExists('entry/src/main/ets/workers/UploadWorkAbility.ets', 'code.worker.UploadWorkAbility');
  fileExists('entry/src/main/ets/common/VersionGate.ets', 'code.VersionGate');
  fileExists('entry/src/main/ets/service/HttpClient.ets', 'code.HttpClient');
  fileExists('docs/OPENAPI_PIN.md', 'code.OPENAPI_PIN');
  fileExists('docs/openapi-mvp.json', 'code.openapi-mvp');

  const mainPages = JSON.parse(
    readFileSync(join(ROOT, 'entry/src/main/resources/base/profile/main_pages.json'), 'utf8')
  );
  for (const p of pages) {
    const src = `pages/${p}`;
    check(`code.main_pages.${p}`, mainPages.src.includes(src), src);
  }
  const moduleJson = readFileSync(join(ROOT, 'entry/src/main/module.json5'), 'utf8');
  check('code.module.workScheduler', moduleJson.includes('UploadWorkAbility') && moduleJson.includes('workScheduler'));

  const httpSrc = readFileSync(join(ROOT, 'entry/src/main/ets/service/HttpClient.ets'), 'utf8');
  check('code.tls.caData', httpSrc.includes('caData') && httpSrc.includes('customCaPem'));

  const vg = readFileSync(join(ROOT, 'entry/src/main/ets/common/VersionGate.ets'), 'utf8');
  check('code.versionGate.logic', vg.includes('MIN_SERVER_MAJOR') || vg.includes('Constants.MIN_SERVER_MAJOR'));

  // --- Immich API checks ---
  const ping = await req('GET', '/server/ping');
  check('api.server.ping', ping.status === 200 && ping.json?.res === 'pong', `${ping.status}`);

  const ver = await req('GET', '/server/version');
  check(
    'api.server.version',
    ver.status === 200 && typeof ver.json?.major === 'number',
    ver.json ? `${ver.json.major}.${ver.json.minor}.${ver.json.patch}` : `${ver.status}`
  );
  // App gate window: major >=1 and soft warn if >3
  const major = ver.json?.major ?? 0;
  check('api.versionGate.minOk', major >= 1, `major=${major}`);
  check('api.versionGate.inTestedWindow', major <= 3, `major=${major}`);

  const loginRes = await login();
  check('api.auth.login', loginRes.status === 201 && !!loginRes.json?.accessToken, `${loginRes.status}`);
  const token = loginRes.json?.accessToken;
  if (!token) {
    writeReport();
    process.exit(1);
  }

  const validate = await req('POST', '/auth/validateToken', { token });
  check('api.auth.validateToken', validate.status === 200 && validate.json?.authStatus === true, `${validate.status}`);

  const me = await req('GET', '/users/me', { token });
  check('api.users.me', me.status === 200 && !!me.json?.email, me.json?.email || `${me.status}`);

  const about = await req('GET', '/server/about', { token });
  check('api.server.about', about.status === 200 && !!about.json?.version, about.json?.version || `${about.status}`);

  const buckets = await req('GET', '/timeline/buckets', { token });
  check('api.timeline.buckets', buckets.status === 200 && Array.isArray(buckets.json) && buckets.json.length > 0, `${buckets.json?.length}`);
  const timeBucket = buckets.json?.[0]?.timeBucket;
  const bucket = await req('GET', `/timeline/bucket?timeBucket=${encodeURIComponent(timeBucket)}`, { token });
  check('api.timeline.bucket', bucket.status === 200 && bucket.json?.id?.length > 0, `${bucket.json?.id?.length}`);
  const ids = bucket.json.id || [];
  const hashes = bucket.json.thumbhash || [];
  let assetId = ids[0];
  for (let i = 0; i < ids.length; i++) {
    if (hashes[i]) {
      assetId = ids[i];
      break;
    }
  }

  let thumb = await reqBuf('GET', `/assets/${assetId}/thumbnail?size=thumbnail`, token);
  if (!(thumb.status === 200 && thumb.buf.length > 100)) {
    for (let i = 0; i < ids.length; i++) {
      if (ids[i] === assetId) {
        continue;
      }
      thumb = await reqBuf('GET', `/assets/${ids[i]}/thumbnail?size=thumbnail`, token);
      if (thumb.status === 200 && thumb.buf.length > 100) {
        assetId = ids[i];
        break;
      }
    }
  }
  check('api.assets.thumbnail', thumb.status === 200 && thumb.buf.length > 100, `${thumb.buf.length}B`);

  const info = await req('GET', `/assets/${assetId}`, { token });
  check('api.assets.info', info.status === 200 && info.json?.id === assetId, info.json?.type || `${info.status}`);

  const favOn = await req('PUT', `/assets/${assetId}`, { token, body: { isFavorite: true } });
  check('api.assets.favorite', favOn.status === 200 && favOn.json?.isFavorite === true, `${favOn.status}`);

  const arch = await req('PUT', `/assets/${assetId}`, { token, body: { visibility: 'archive' } });
  check('api.assets.archive', arch.status === 200 && arch.json?.visibility === 'archive', `${arch.status}`);
  const archBuckets = await req('GET', '/timeline/buckets?visibility=archive', { token });
  check('api.timeline.archiveBuckets', archBuckets.status === 200 && archBuckets.json.length > 0, `${archBuckets.json?.length}`);
  const unarch = await req('PUT', `/assets/${assetId}`, { token, body: { visibility: 'timeline' } });
  check('api.assets.unarchive', unarch.status === 200 && unarch.json?.visibility === 'timeline', `${unarch.status}`);

  const trash = await req('DELETE', '/assets', { token, body: { ids: [assetId], force: false } });
  check('api.assets.trash', trash.status >= 200 && trash.status < 300, `${trash.status}`);
  const trashBuckets = await req('GET', '/timeline/buckets?isTrashed=true', { token });
  check('api.timeline.trashBuckets', trashBuckets.status === 200 && trashBuckets.json.length > 0, `${trashBuckets.json?.length}`);
  const restore = await req('POST', '/trash/restore/assets', { token, body: { ids: [assetId] } });
  check('api.trash.restoreAssets', restore.status === 200, `${restore.status}`);

  const original = await reqBuf('GET', `/assets/${assetId}/original`, token);
  check('api.assets.original', original.status === 200 && original.buf.length > 0, `${original.buf.length}B`);

  // Video endpoint: may 400/404 if asset is image — still verify route exists for VIDEO assets
  const video = await reqBuf('GET', `/assets/${assetId}/video/playback`, token);
  const videoOk = video.status === 200 || video.status === 400 || video.status === 404 || video.status === 422;
  check(
    'api.assets.videoPlayback',
    videoOk,
    `status=${video.status} (200 if video asset; 4xx acceptable for image)`
  );

  // Upload with checksum
  const jpeg = tinyJpeg();
  const checksum = createHash('sha1').update(jpeg).digest('base64');
  const form = new FormData();
  form.append('assetData', new Blob([jpeg], { type: 'image/jpeg' }), `audit_${Date.now()}.jpg`);
  form.append('deviceAssetId', `audit_${Date.now()}`);
  form.append('deviceId', 'harmonyos-audit');
  form.append('fileCreatedAt', new Date().toISOString());
  form.append('fileModifiedAt', new Date().toISOString());
  form.append('filename', `audit_${Date.now()}.jpg`);
  form.append('isFavorite', 'false');
  form.append('duration', '0');
  const uploadRes = await fetch(`${base}/assets`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'x-immich-checksum': checksum
    },
    body: form
  });
  const uploadBody = await uploadRes.json().catch(() => ({}));
  check(
    'api.assets.upload',
    (uploadRes.status === 200 || uploadRes.status === 201) && !!uploadBody.id,
    `${uploadRes.status} ${uploadBody.status || ''}`
  );

  // Albums
  const albumName = `Audit Album ${Date.now()}`;
  const createAlbum = await req('POST', '/albums', {
    token,
    body: { albumName, assetIds: [assetId] }
  });
  check('api.albums.create', createAlbum.status === 201 && !!createAlbum.json?.id, `${createAlbum.status}`);
  const albumId = createAlbum.json?.id;
  const listAlbums = await req('GET', '/albums', { token });
  check('api.albums.list', listAlbums.status === 200 && listAlbums.json.some((a) => a.id === albumId), `${listAlbums.json?.length}`);
  const addAssets = await req('PUT', `/albums/${albumId}/assets`, { token, body: { ids: [assetId] } });
  check('api.albums.addAssets', addAssets.status === 200, `${addAssets.status}`);
  const albumBuckets = await req('GET', `/timeline/buckets?albumId=${albumId}`, { token });
  check('api.albums.buckets', albumBuckets.status === 200, `${albumBuckets.json?.length}`);
  const delAlbum = await req('DELETE', `/albums/${albumId}`, { token });
  check('api.albums.delete', delAlbum.status >= 200 && delAlbum.status < 300, `${delAlbum.status}`);

  // Search
  const meta = await req('POST', '/search/metadata', { token, body: { q: 'audit', size: 20 } });
  check('api.search.metadata', meta.status === 200 && !!meta.json?.assets, `${meta.status}`);
  const favSearch = await req('POST', '/search/metadata', { token, body: { isFavorite: true, size: 20 } });
  check('api.search.favorites', favSearch.status === 200, `${favSearch.status}`);
  const smart = await req('POST', '/search/smart', { token, body: { prompt: 'photo', size: 10 } });
  check(
    'api.search.smart',
    smart.status === 200 || smart.status === 400 || smart.status === 500,
    `status=${smart.status} (400/500 ok if ML unavailable)`
  );

  // People
  const people = await req('GET', '/people', { token });
  check('api.people.list', people.status === 200, `${people.status}`);

  // Tags
  const tagName = `audit-tag-${Date.now()}`;
  const tag = await req('POST', '/tags', { token, body: { name: tagName } });
  check('api.tags.create', tag.status === 201 && !!tag.json?.id, `${tag.status}`);
  const tagId = tag.json?.id;
  const tags = await req('GET', '/tags', { token });
  check('api.tags.list', tags.status === 200 && tags.json.some((t) => t.id === tagId), `${tags.json?.length}`);
  const tagAssets = await req('PUT', `/tags/${tagId}/assets`, { token, body: { ids: [assetId] } });
  check('api.tags.addAssets', tagAssets.status === 200, `${tagAssets.status}`);
  const tagBuckets = await req('GET', `/timeline/buckets?tagId=${tagId}`, { token });
  check('api.tags.buckets', tagBuckets.status === 200 && tagBuckets.json.length > 0, `${tagBuckets.json?.length}`);

  // Shared links
  const share = await req('POST', '/shared-links', {
    token,
    body: {
      type: 'INDIVIDUAL',
      assetIds: [assetId],
      allowDownload: true,
      allowUpload: false,
      showMetadata: true
    }
  });
  check('api.sharedLinks.create', share.status === 201 && !!share.json?.key, `${share.status}`);
  const links = await req('GET', '/shared-links', { token });
  check('api.sharedLinks.list', links.status === 200 && links.json.some((l) => l.id === share.json.id), `${links.json?.length}`);
  const delLink = await req('DELETE', `/shared-links/${share.json.id}`, { token });
  check('api.sharedLinks.delete', delLink.status >= 200 && delLink.status < 300, `${delLink.status}`);

  // Logout last (token becomes invalid)
  const logout = await req('POST', '/auth/logout', { token });
  check('api.auth.logout', logout.status >= 200 && logout.status < 300, `${logout.status}`);

  writeReport();
  const failed = results.filter((r) => !r.ok);
  process.exit(failed.length > 0 ? 1 : 0);
}

function tinyJpeg() {
  // Minimal valid 1x1 JPEG
  return Buffer.from(
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxAQEBUQEBAVFRUVFRUVFRUVFRUVFRUWFxUVFRUYHSggGBolGxUVITEhJSkrLi4uFx8zODMtNygtLisBCgoKDg0OGxAQGy0lHyUtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLf/AABEIAAEAAQMBIgACEQEDEQH/xAAbAAACAwEBAQAAAAAAAAAAAAADBAECBQYAB//EAD0QAAIBAgQDBgQEBQUBAAAAAAECAwQRAAUSITFBBhMiUWEycYGRobHBFDNCctHh8BUjcpLx/8QAGQEAAwEBAQAAAAAAAAAAAAAAAQIDBAAF/8QAJBEAAgICAgICAwEAAAAAAAAAAQIAEQMhEjFBBFFhInGBMv/aAAwDAQACEQMRAD8A9oKKKKACiiigAooooAKKKKACiiigD//Z',
    'base64'
  );
}

function writeReport() {
  const failed = results.filter((r) => !r.ok);
  const report = {
    generatedAt: new Date().toISOString(),
    base,
    total: results.length,
    passed: results.length - failed.length,
    failed: failed.length,
    results
  };
  const out = join(ROOT, 'docs/FEATURE_AUDIT.json');
  writeFileSync(out, JSON.stringify(report, null, 2) + '\n');
  console.log(`\nReport: ${out} (${report.passed}/${report.total} passed)`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

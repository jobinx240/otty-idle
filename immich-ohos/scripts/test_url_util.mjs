#!/usr/bin/env node
/** Mirrors entry/.../UrlUtil.ets for a quick sanity check without DevEco. */

function normalizeApiBaseUrl(raw) {
  let url = raw.trim();
  if (url.endsWith('/')) {
    url = url.slice(0, url.length - 1);
  }
  if (url.endsWith('/api')) {
    return url;
  }
  return `${url}/api`;
}

function serverOriginFromApiBase(apiBase) {
  if (apiBase.endsWith('/api')) {
    return apiBase.slice(0, apiBase.length - 4);
  }
  return apiBase;
}

const cases = [
  ['https://photo.example.com', 'https://photo.example.com/api'],
  ['https://photo.example.com/', 'https://photo.example.com/api'],
  ['https://photo.example.com/api', 'https://photo.example.com/api'],
  ['https://photo.example.com/api/', 'https://photo.example.com/api'],
];

let failed = 0;
for (const [input, expected] of cases) {
  const got = normalizeApiBaseUrl(input);
  if (got !== expected) {
    console.error(`FAIL normalize(${input}) => ${got}, expected ${expected}`);
    failed += 1;
  }
}

const origin = serverOriginFromApiBase('https://photo.example.com/api');
if (origin !== 'https://photo.example.com') {
  console.error(`FAIL origin => ${origin}`);
  failed += 1;
}

if (failed > 0) {
  process.exit(1);
}
console.log('url util ok');

#!/usr/bin/env node
/**
 * Mirrors ChecksumUtil.hexToBase64 / Immich x-immich-checksum encoding.
 */
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';

function hexToBase64(hex) {
  const clean = hex.replace(/\s+/g, '');
  if (clean.length === 0 || clean.length % 2 !== 0) {
    return '';
  }
  const bytes = Buffer.from(clean, 'hex');
  return bytes.toString('base64');
}

const sample = Buffer.from('immich-ohos-checksum');
const digest = createHash('sha1').update(sample).digest();
const expected = digest.toString('base64');
const fromHex = hexToBase64(digest.toString('hex').toUpperCase());
assert.equal(fromHex, expected);
assert.equal(hexToBase64(''), '');
assert.equal(hexToBase64('abc'), '');
console.log(JSON.stringify({ ok: true, sample: expected }));

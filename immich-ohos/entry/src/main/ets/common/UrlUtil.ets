/**
 * Normalize a user-entered Immich server URL to origin + /api.
 */
export function normalizeApiBaseUrl(raw: string): string {
  let url = raw.trim();
  if (url.endsWith('/')) {
    url = url.slice(0, url.length - 1);
  }
  if (url.endsWith('/api')) {
    return url;
  }
  return `${url}/api`;
}

/**
 * Origin without /api, used for display and media URLs.
 */
export function serverOriginFromApiBase(apiBase: string): string {
  if (apiBase.endsWith('/api')) {
    return apiBase.slice(0, apiBase.length - 4);
  }
  return apiBase;
}

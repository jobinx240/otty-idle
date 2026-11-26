import { http } from '@kit.NetworkKit';
import { SessionStore } from './SessionStore';
import { normalizeApiBaseUrl } from '../common/UrlUtil';

export class HttpError extends Error {
  code: number;

  constructor(code: number, message: string) {
    super(message);
    this.code = code;
  }
}

/**
 * Thin Immich API HTTP helper. Base URL is origin + /api.
 */
export class HttpClient {
  private apiBase: string = '';
  private accessToken: string = '';

  async loadFromSession(): Promise<void> {
    const raw = await SessionStore.getServerUrl();
    this.apiBase = raw.length > 0 ? normalizeApiBaseUrl(raw) : '';
    this.accessToken = await SessionStore.getAccessToken();
  }

  setEndpoint(serverUrl: string, accessToken: string = ''): void {
    this.apiBase = normalizeApiBaseUrl(serverUrl);
    this.accessToken = accessToken;
  }

  getApiBase(): string {
    return this.apiBase;
  }

  getAccessToken(): string {
    return this.accessToken;
  }

  /** Shared Immich auth headers for JSON and binary requests. */
  authHeaders(extra?: Record<string, string>): Record<string, string> {
    const headers: Record<string, string> = {};
    if (extra) {
      const keys = Object.keys(extra);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        headers[key] = extra[key];
      }
    }
    if (this.accessToken.length > 0) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
      headers['x-immich-user-token'] = this.accessToken;
    }
    return headers;
  }

  async getJson<T>(path: string, query?: Record<string, string>): Promise<T> {
    return this.requestJson<T>('GET', path, undefined, query);
  }

  async postJson<T>(path: string, body?: object): Promise<T> {
    return this.requestJson<T>('POST', path, body);
  }

  async putJson<T>(path: string, body?: object): Promise<T> {
    return this.requestJson<T>('PUT', path, body);
  }

  async deleteJson<T>(path: string, body?: object): Promise<T> {
    return this.requestJson<T>('DELETE', path, body);
  }

  /**
   * GET binary body (thumbnails / original bytes).
   */
  async getArrayBuffer(path: string, query?: Record<string, string>): Promise<ArrayBuffer> {
    const url = this.buildUrl(path, query);
    const client = http.createHttp();
    try {
      const response = await client.request(url, {
        method: http.RequestMethod.GET,
        header: this.authHeaders({ 'Accept': '*/*' }),
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 60000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new HttpError(response.responseCode, `HTTP ${response.responseCode}`);
      }
      return response.result as ArrayBuffer;
    } finally {
      client.destroy();
    }
  }

  /**
   * POST multipart/form-data (asset upload).
   * @param extraHeaders optional Immich headers such as x-immich-checksum
   */
  async postMultipart<T>(
    path: string,
    forms: Array<http.MultiFormData>,
    extraHeaders?: Record<string, string>
  ): Promise<T> {
    const url = this.buildUrl(path);
    const client = http.createHttp();
    try {
      const headers: Record<string, string> = {
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data'
      };
      if (extraHeaders) {
        const keys = Object.keys(extraHeaders);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          headers[key] = extraHeaders[key];
        }
      }
      const response = await client.request(url, {
        method: http.RequestMethod.POST,
        header: this.authHeaders(headers),
        multiFormDataList: forms,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: 300000
      });
      const code = response.responseCode;
      const raw = typeof response.result === 'string' ? response.result : `${response.result}`;
      // Immich returns 200 (duplicate) or 201 (created)
      if (code < 200 || code >= 300) {
        throw new HttpError(code, raw.length > 0 ? raw : `HTTP ${code}`);
      }
      if (raw.length === 0) {
        return undefined as T;
      }
      return JSON.parse(raw) as T;
    } finally {
      client.destroy();
    }
  }

  thumbnailUrl(assetId: string, size: string = 'thumbnail'): string {
    return this.buildUrl(`/assets/${assetId}/thumbnail`, { 'size': size });
  }

  private buildUrl(path: string, query?: Record<string, string>): string {
    if (this.apiBase.length === 0) {
      throw new HttpError(0, 'Server URL is not set');
    }
    let url = `${this.apiBase}${path.startsWith('/') ? path : `/${path}`}`;
    if (query) {
      const parts: string[] = [];
      const keys = Object.keys(query);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(query[key])}`);
      }
      if (parts.length > 0) {
        url = `${url}?${parts.join('&')}`;
      }
    }
    return url;
  }

  private async requestJson<T>(
    method: http.RequestMethod | string,
    path: string,
    body?: object,
    query?: Record<string, string>
  ): Promise<T> {
    const url = this.buildUrl(path, query);
    const client = http.createHttp();
    try {
      const response = await client.request(url, {
        method: method as http.RequestMethod,
        header: this.authHeaders({
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }),
        extraData: body ? JSON.stringify(body) : undefined,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 30000
      });

      const code = response.responseCode;
      const raw = typeof response.result === 'string' ? response.result : `${response.result}`;
      if (code < 200 || code >= 300) {
        throw new HttpError(code, raw.length > 0 ? raw : `HTTP ${code}`);
      }
      if (raw.length === 0) {
        return undefined as T;
      }
      return JSON.parse(raw) as T;
    } finally {
      client.destroy();
    }
  }
}

/** Process-wide client used by pages after EntryAbility init. */
export const immichHttp: HttpClient = new HttpClient();

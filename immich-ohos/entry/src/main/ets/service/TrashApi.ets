import { HttpClient, immichHttp } from './HttpClient';

class BulkIdsBody {
  ids: string[];

  constructor(ids: string[]) {
    this.ids = ids;
  }
}

/**
 * Immich trash restore / empty APIs.
 */
export class TrashApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  /** POST /trash/restore/assets — restore selected trashed assets. */
  async restoreAssets(ids: string[]): Promise<void> {
    await this.http.postJson<void>('/trash/restore/assets', new BulkIdsBody(ids));
  }

  /** POST /trash/restore — restore everything in trash. */
  async restoreAll(): Promise<void> {
    await this.http.postJson<void>('/trash/restore');
  }

  /** POST /trash/empty — permanently delete trash. */
  async emptyTrash(): Promise<void> {
    await this.http.postJson<void>('/trash/empty');
  }
}

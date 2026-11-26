import { HttpClient, immichHttp } from './HttpClient';
import { SharedLinkResponseDto } from '../model/TagModels';
import { serverOriginFromApiBase } from '../common/UrlUtil';

class CreateSharedLinkBody {
  type: string;
  assetIds?: string[];
  albumId?: string;
  allowDownload: boolean;
  allowUpload: boolean;
  showMetadata: boolean;

  constructor(type: string) {
    this.type = type;
    this.allowDownload = true;
    this.allowUpload = false;
    this.showMetadata = true;
  }
}

/**
 * Immich shared-link create / list / delete.
 */
export class SharedLinkApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  async list(): Promise<SharedLinkResponseDto[]> {
    return this.http.getJson<SharedLinkResponseDto[]>('/shared-links');
  }

  /** Create an individual-asset share link. */
  async createForAsset(assetId: string): Promise<SharedLinkResponseDto> {
    const body = new CreateSharedLinkBody('INDIVIDUAL');
    body.assetIds = [assetId];
    return this.http.postJson<SharedLinkResponseDto>('/shared-links', body);
  }

  async delete(id: string): Promise<void> {
    await this.http.deleteJson<void>(`/shared-links/${id}`);
  }

  /** Public web URL for a shared link key (or slug). */
  static publicUrl(apiBase: string, link: SharedLinkResponseDto): string {
    const origin = serverOriginFromApiBase(apiBase);
    if (link.slug && link.slug.length > 0) {
      return `${origin}/s/${encodeURIComponent(link.slug)}`;
    }
    return `${origin}/share/${link.key}`;
  }
}

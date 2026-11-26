import { HttpClient, immichHttp } from './HttpClient';
import { TagResponseDto } from '../model/TagModels';

class CreateTagBody {
  name: string;

  constructor(name: string) {
    this.name = name;
  }
}

class BulkIdsBody {
  ids: string[];

  constructor(ids: string[]) {
    this.ids = ids;
  }
}

/**
 * Immich tags list / create / attach assets.
 */
export class TagApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  async listTags(): Promise<TagResponseDto[]> {
    return this.http.getJson<TagResponseDto[]>('/tags');
  }

  async createTag(name: string): Promise<TagResponseDto> {
    return this.http.postJson<TagResponseDto>('/tags', new CreateTagBody(name));
  }

  /** PUT /tags/{id}/assets */
  async addAssets(tagId: string, assetIds: string[]): Promise<void> {
    await this.http.putJson<void>(`/tags/${tagId}/assets`, new BulkIdsBody(assetIds));
  }
}

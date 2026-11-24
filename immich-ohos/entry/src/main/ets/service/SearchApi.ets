import { HttpClient, immichHttp } from './HttpClient';
import { SearchResponseDto } from '../model/AlbumModels';

class MetadataSearchBody {
  q: string;
  size: number;

  constructor(q: string, size: number) {
    this.q = q;
    this.size = size;
  }
}

/**
 * Immich metadata search.
 */
export class SearchApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  async searchMetadata(query: string, size: number = 60): Promise<SearchResponseDto> {
    return this.http.postJson<SearchResponseDto>('/search/metadata', new MetadataSearchBody(query, size));
  }
}

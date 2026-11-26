import { HttpClient, immichHttp } from './HttpClient';
import { SearchResponseDto } from '../model/AlbumModels';

class MetadataSearchBody {
  q?: string;
  size: number;
  isFavorite?: boolean;
  personIds?: string[];

  constructor(size: number) {
    this.size = size;
  }
}

class SmartSearchBody {
  prompt: string;
  size: number;

  constructor(prompt: string, size: number) {
    this.prompt = prompt;
    this.size = size;
  }
}

/**
 * Immich metadata + smart search.
 */
export class SearchApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  async searchMetadata(query: string, size: number = 60): Promise<SearchResponseDto> {
    const body = new MetadataSearchBody(size);
    body.q = query;
    return this.http.postJson<SearchResponseDto>('/search/metadata', body);
  }

  /** Favorites-only metadata search (empty query). */
  async searchFavorites(size: number = 120): Promise<SearchResponseDto> {
    const body = new MetadataSearchBody(size);
    body.isFavorite = true;
    return this.http.postJson<SearchResponseDto>('/search/metadata', body);
  }

  /** Assets for one person id. */
  async searchByPerson(personId: string, size: number = 120): Promise<SearchResponseDto> {
    const body = new MetadataSearchBody(size);
    body.personIds = [personId];
    return this.http.postJson<SearchResponseDto>('/search/metadata', body);
  }

  /**
   * CLIP smart search. May 400 if ML is disabled on the server.
   */
  async searchSmart(prompt: string, size: number = 60): Promise<SearchResponseDto> {
    return this.http.postJson<SearchResponseDto>('/search/smart', new SmartSearchBody(prompt, size));
  }
}

import { HttpClient, immichHttp } from './HttpClient';
import { ServerAboutResponseDto, ServerVersionResponseDto } from '../model/PeopleModels';

/**
 * Immich server info for Settings.
 */
export class ServerApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  async about(): Promise<ServerAboutResponseDto> {
    return this.http.getJson<ServerAboutResponseDto>('/server/about');
  }

  async version(): Promise<ServerVersionResponseDto> {
    return this.http.getJson<ServerVersionResponseDto>('/server/version');
  }
}

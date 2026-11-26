import { HttpClient, immichHttp } from './HttpClient';
import { PeopleListResponseDto, PersonResponseDto } from '../model/PeopleModels';

/**
 * Immich people (face clusters) API.
 */
export class PeopleApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  /** GET /people — named and unnamed people. */
  async listPeople(): Promise<PersonResponseDto[]> {
    const data = await this.http.getJson<Object>('/people');
    if (Array.isArray(data)) {
      return data as PersonResponseDto[];
    }
    const wrapped = data as PeopleListResponseDto;
    return wrapped.people ?? [];
  }
}

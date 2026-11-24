import { HttpClient, immichHttp } from './HttpClient';
import { AlbumListItem } from '../model/AlbumModels';
import { TimeBucketAssetResponseDto, TimeBucketsResponseDto } from '../model/TimelineModels';

/**
 * Immich album listing + album-scoped timeline buckets.
 */
export class AlbumApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  async listAlbums(): Promise<AlbumListItem[]> {
    return this.http.getJson<AlbumListItem[]>('/albums');
  }

  async getAlbumBuckets(albumId: string): Promise<TimeBucketsResponseDto[]> {
    return this.http.getJson<TimeBucketsResponseDto[]>('/timeline/buckets', {
      'albumId': albumId
    });
  }

  async getAlbumBucket(albumId: string, timeBucket: string): Promise<TimeBucketAssetResponseDto> {
    return this.http.getJson<TimeBucketAssetResponseDto>('/timeline/bucket', {
      'albumId': albumId,
      'timeBucket': timeBucket
    });
  }
}

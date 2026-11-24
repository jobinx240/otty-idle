import { HttpClient } from './HttpClient';
import { TimeBucketAssetResponseDto, TimeBucketsResponseDto } from '../model/TimelineModels';

/**
 * Immich timeline bucket APIs for the photo grid.
 */
export class TimelineApi {
  private http: HttpClient;

  constructor(http: HttpClient) {
    this.http = http;
  }

  async getBuckets(albumId?: string): Promise<TimeBucketsResponseDto[]> {
    if (albumId && albumId.length > 0) {
      return this.http.getJson<TimeBucketsResponseDto[]>('/timeline/buckets', {
        'albumId': albumId
      });
    }
    return this.http.getJson<TimeBucketsResponseDto[]>('/timeline/buckets');
  }

  async getBucket(timeBucket: string, albumId?: string): Promise<TimeBucketAssetResponseDto> {
    if (albumId && albumId.length > 0) {
      return this.http.getJson<TimeBucketAssetResponseDto>('/timeline/bucket', {
        'albumId': albumId,
        'timeBucket': timeBucket
      });
    }
    return this.http.getJson<TimeBucketAssetResponseDto>('/timeline/bucket', {
      'timeBucket': timeBucket
    });
  }
}

import { HttpClient } from './HttpClient';
import { TimeBucketAssetResponseDto, TimeBucketsResponseDto } from '../model/TimelineModels';

/** Optional filters for timeline bucket queries. */
export class TimelineFilter {
  albumId: string = '';
  isTrashed: boolean = false;
  /** Immich AssetVisibility: timeline | archive | hidden | locked */
  visibility: string = '';

  static album(albumId: string): TimelineFilter {
    const f = new TimelineFilter();
    f.albumId = albumId;
    return f;
  }

  static trash(): TimelineFilter {
    const f = new TimelineFilter();
    f.isTrashed = true;
    return f;
  }

  static archive(): TimelineFilter {
    const f = new TimelineFilter();
    f.visibility = 'archive';
    return f;
  }
}

/**
 * Immich timeline bucket APIs for the photo grid.
 */
export class TimelineApi {
  private http: HttpClient;

  constructor(http: HttpClient) {
    this.http = http;
  }

  async getBuckets(filter?: TimelineFilter): Promise<TimeBucketsResponseDto[]> {
    return this.http.getJson<TimeBucketsResponseDto[]>('/timeline/buckets', this.toQuery(filter));
  }

  async getBucket(timeBucket: string, filter?: TimelineFilter): Promise<TimeBucketAssetResponseDto> {
    const query = this.toQuery(filter) ?? {};
    query['timeBucket'] = timeBucket;
    return this.http.getJson<TimeBucketAssetResponseDto>('/timeline/bucket', query);
  }

  private toQuery(filter?: TimelineFilter): Record<string, string> | undefined {
    if (!filter) {
      return undefined;
    }
    const query: Record<string, string> = {};
    if (filter.albumId.length > 0) {
      query['albumId'] = filter.albumId;
    }
    if (filter.isTrashed) {
      query['isTrashed'] = 'true';
    }
    if (filter.visibility.length > 0) {
      query['visibility'] = filter.visibility;
    }
    return Object.keys(query).length > 0 ? query : undefined;
  }
}

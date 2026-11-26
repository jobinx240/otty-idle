import { HttpClient, immichHttp } from './HttpClient';
import { AlbumListItem } from '../model/AlbumModels';
import { TimeBucketAssetResponseDto, TimeBucketsResponseDto } from '../model/TimelineModels';

class CreateAlbumBody {
  albumName: string;
  assetIds?: string[];

  constructor(albumName: string, assetIds?: string[]) {
    this.albumName = albumName;
    if (assetIds && assetIds.length > 0) {
      this.assetIds = assetIds;
    }
  }
}

class BulkIdsBody {
  ids: string[];

  constructor(ids: string[]) {
    this.ids = ids;
  }
}

/**
 * Immich album listing, create, and album-scoped timeline buckets.
 */
export class AlbumApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  async listAlbums(): Promise<AlbumListItem[]> {
    return this.http.getJson<AlbumListItem[]>('/albums');
  }

  /** POST /albums — create album, optionally with initial assets. */
  async createAlbum(albumName: string, assetIds?: string[]): Promise<AlbumListItem> {
    return this.http.postJson<AlbumListItem>('/albums', new CreateAlbumBody(albumName, assetIds));
  }

  /** PUT /albums/{id}/assets — add assets to an album. */
  async addAssets(albumId: string, assetIds: string[]): Promise<void> {
    await this.http.putJson<void>(`/albums/${albumId}/assets`, new BulkIdsBody(assetIds));
  }

  /** DELETE /albums/{id} */
  async deleteAlbum(albumId: string): Promise<void> {
    await this.http.deleteJson<void>(`/albums/${albumId}`);
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

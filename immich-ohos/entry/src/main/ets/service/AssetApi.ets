import { http } from '@kit.NetworkKit';
import { HttpClient, immichHttp } from './HttpClient';
import { AssetMediaResponseDto, AssetResponseDto } from '../model/AssetModels';
import { ChecksumUtil } from '../common/ChecksumUtil';

class UpdateFavoriteBody {
  isFavorite: boolean;

  constructor(isFavorite: boolean) {
    this.isFavorite = isFavorite;
  }
}

class BulkDeleteBody {
  ids: string[];
  force: boolean;

  constructor(ids: string[], force: boolean) {
    this.ids = ids;
    this.force = force;
  }
}

/**
 * Immich asset upload / detail / favorite / trash API.
 */
export class AssetApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  /** GET /assets/{id} */
  async getInfo(id: string): Promise<AssetResponseDto> {
    return this.http.getJson<AssetResponseDto>(`/assets/${id}`);
  }

  /** PUT /assets/{id} — toggle favorite. */
  async setFavorite(id: string, isFavorite: boolean): Promise<AssetResponseDto> {
    return this.http.putJson<AssetResponseDto>(`/assets/${id}`, new UpdateFavoriteBody(isFavorite));
  }

  /**
   * DELETE /assets — soft-delete (trash) unless force is true.
   */
  async deleteAssets(ids: string[], force: boolean = false): Promise<void> {
    await this.http.deleteJson<void>('/assets', new BulkDeleteBody(ids, force));
  }

  /**
   * Upload one local file URI to Immich.
   * Adds x-immich-checksum (SHA-1 Base64) when the path is hashable.
   */
  async uploadFile(
    fileUri: string,
    fileName: string,
    deviceAssetId: string,
    fileCreatedAtIso: string,
    fileModifiedAtIso: string,
    deviceId: string = 'harmonyos'
  ): Promise<AssetMediaResponseDto> {
    const forms: Array<http.MultiFormData> = [
      {
        name: 'assetData',
        contentType: this.guessContentType(fileName),
        filePath: fileUri,
        remoteFileName: fileName
      },
      {
        name: 'fileCreatedAt',
        contentType: 'text/plain',
        data: fileCreatedAtIso
      },
      {
        name: 'fileModifiedAt',
        contentType: 'text/plain',
        data: fileModifiedAtIso
      },
      {
        name: 'filename',
        contentType: 'text/plain',
        data: fileName
      },
      {
        name: 'deviceAssetId',
        contentType: 'text/plain',
        data: deviceAssetId
      },
      {
        name: 'deviceId',
        contentType: 'text/plain',
        data: deviceId
      },
      {
        name: 'isFavorite',
        contentType: 'text/plain',
        data: 'false'
      },
      {
        name: 'duration',
        contentType: 'text/plain',
        data: '0'
      }
    ];

    const checksum = await ChecksumUtil.sha1Base64ForPath(fileUri);
    const extra: Record<string, string> = {};
    if (checksum.length > 0) {
      extra['x-immich-checksum'] = checksum;
    }
    return this.http.postMultipart<AssetMediaResponseDto>('/assets', forms, extra);
  }

  /**
   * Stable-ish id from URI for duplicate-friendly uploads on older servers.
   */
  static deviceAssetIdFromUri(uri: string): string {
    let hash = 0;
    for (let i = 0; i < uri.length; i++) {
      hash = ((hash << 5) - hash) + uri.charCodeAt(i);
      hash |= 0;
    }
    return `ohos_${Math.abs(hash)}`;
  }

  private guessContentType(fileName: string): string {
    const lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    if (lower.endsWith('.mp4')) {
      return 'video/mp4';
    }
    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }
    return 'image/jpeg';
  }
}

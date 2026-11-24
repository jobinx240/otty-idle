import { http } from '@kit.NetworkKit';
import { HttpClient, immichHttp } from './HttpClient';
import { AssetMediaResponseDto } from '../model/AssetModels';

/**
 * Immich asset upload API (multipart).
 */
export class AssetApi {
  private http: HttpClient;

  constructor(httpClient: HttpClient = immichHttp) {
    this.http = httpClient;
  }

  /**
   * Upload one local file URI to Immich.
   * Sends deviceAssetId/deviceId for older Immich servers; current OpenAPI marks them optional.
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

    return this.http.postMultipart<AssetMediaResponseDto>('/assets', forms);
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

/**
 * POST /assets response.
 */
export interface AssetMediaResponseDto {
  id: string;
  status: string; // created | duplicate
}

/**
 * Local file selected for backup upload.
 */
export class LocalUploadItem {
  uri: string;
  fileName: string;
  deviceAssetId: string;
  status: string; // pending | uploading | done | error | duplicate
  message: string;
  remoteId: string;

  constructor(uri: string, fileName: string, deviceAssetId: string) {
    this.uri = uri;
    this.fileName = fileName;
    this.deviceAssetId = deviceAssetId;
    this.status = 'pending';
    this.message = '';
    this.remoteId = '';
  }
}

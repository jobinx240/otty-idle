/**
 * POST /assets response.
 */
export interface AssetMediaResponseDto {
  id: string;
  status: string; // created | duplicate
}

/**
 * Subset of GET /assets/{id} used by the viewer and settings.
 */
export interface AssetResponseDto {
  id: string;
  type: string;
  originalFileName?: string;
  originalMimeType?: string;
  isFavorite?: boolean;
  isArchived?: boolean;
  isTrashed?: boolean;
  /** Immich AssetVisibility: timeline | archive | hidden | locked */
  visibility?: string;
  duration?: number | null;
  localDateTime?: string;
  fileCreatedAt?: string;
  exifInfo?: ExifResponseDto;
}

/** Optional EXIF fields shown in the asset viewer. */
export interface ExifResponseDto {
  make?: string | null;
  model?: string | null;
  exifImageWidth?: number | null;
  exifImageHeight?: number | null;
  city?: string | null;
  country?: string | null;
  description?: string | null;
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

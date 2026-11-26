/**
 * GET /timeline/buckets item.
 */
export interface TimeBucketsResponseDto {
  timeBucket: string;
  count: number;
}

/**
 * Minimal asset fields for timeline grid cells.
 */
export interface TimelineAssetDto {
  id: string;
  type: string;
  originalFileName?: string;
  localDateTime?: string;
  thumbhash?: string;
}

/**
 * GET /timeline/bucket payload (columnar arrays from Immich).
 */
export interface TimeBucketAssetResponseDto {
  id: string[];
  isImage?: boolean[];
  isFavorite?: boolean[];
  duration?: (number | null)[];
}

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
 * GET /timeline/bucket payload (shape may include nested arrays; MVP reads id list).
 */
export interface TimeBucketAssetResponseDto {
  id: string[];
}
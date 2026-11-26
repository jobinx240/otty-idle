/**
 * GET /albums item — AlbumResponseDto subset.
 */
export interface AlbumListItem {
  id: string;
  albumName: string;
  description?: string;
  assetCount: number;
  albumThumbnailAssetId?: string | null;
  shared?: boolean;
}

/**
 * POST /search/metadata response assets page.
 */
export interface SearchAssetsPage {
  total?: number;
  count?: number;
  items: SearchAssetItem[];
}

export interface SearchAssetItem {
  id: string;
  type?: string;
  originalFileName?: string;
}

export interface SearchResponseDto {
  assets: SearchAssetsPage;
}

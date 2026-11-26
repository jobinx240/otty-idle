/**
 * GET /people item — PersonResponseDto subset.
 */
export interface PersonResponseDto {
  id: string;
  name?: string;
  isHidden?: boolean;
  isFavorite?: boolean;
  thumbnailPath?: string;
}

/** Some Immich versions wrap the people list. */
export interface PeopleListResponseDto {
  people?: PersonResponseDto[];
}

/**
 * GET /server/about subset for the settings page.
 */
export interface ServerAboutResponseDto {
  version?: string;
  versionUrl?: string;
  repository?: string;
  sourceRef?: string;
  sourceCommit?: string;
  sourceUrl?: string;
  build?: string;
}

/**
 * GET /server/version subset.
 */
export interface ServerVersionResponseDto {
  major?: number;
  minor?: number;
  patch?: number;
}

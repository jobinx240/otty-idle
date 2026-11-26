/** GET /tags item — TagResponseDto subset. */
export interface TagResponseDto {
  id: string;
  name: string;
  value?: string;
  color?: string | null;
}

/** GET /shared-links item — SharedLinkResponseDto subset. */
export interface SharedLinkResponseDto {
  id: string;
  key: string;
  type: string;
  description?: string | null;
  allowDownload?: boolean;
  allowUpload?: boolean;
  createdAt?: string;
  expiresAt?: string | null;
  slug?: string | null;
}

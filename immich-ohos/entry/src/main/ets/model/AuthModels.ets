/**
 * POST /auth/login body — LoginCredentialDto.
 */
export interface LoginCredentialDto {
  email: string;
  password: string;
}

/**
 * POST /auth/login response — LoginResponseDto (subset used by MVP).
 */
export interface LoginResponseDto {
  accessToken: string;
  userId: string;
  userEmail: string;
  name?: string | null;
  isAdmin: boolean;
  isOnboarded?: boolean;
}

/**
 * POST /auth/validateToken response.
 */
export interface ValidateAccessTokenResponseDto {
  authStatus: boolean;
}

/**
 * GET /server/ping response.
 */
export interface ServerPingResponse {
  res: string;
}

/**
 * GET /users/me — fields needed for the header.
 */
export interface UserMeDto {
  id: string;
  email: string;
  name?: string | null;
  isAdmin: boolean;
}

import { HttpClient } from './HttpClient';
import {
  LoginCredentialDto,
  LoginResponseDto,
  ServerPingResponse,
  UserMeDto,
  ValidateAccessTokenResponseDto
} from '../model/AuthModels';

/**
 * Immich authentication and session-related API calls.
 */
export class AuthApi {
  private http: HttpClient;

  constructor(http: HttpClient) {
    this.http = http;
  }

  async ping(): Promise<ServerPingResponse> {
    return this.http.getJson<ServerPingResponse>('/server/ping');
  }

  async login(email: string, password: string): Promise<LoginResponseDto> {
    const body: LoginCredentialDto = { email, password };
    return this.http.postJson<LoginResponseDto>('/auth/login', body);
  }

  async validateToken(): Promise<ValidateAccessTokenResponseDto> {
    return this.http.postJson<ValidateAccessTokenResponseDto>('/auth/validateToken');
  }

  async logout(): Promise<void> {
    await this.http.postJson<void>('/auth/logout');
  }

  async getMe(): Promise<UserMeDto> {
    return this.http.getJson<UserMeDto>('/users/me');
  }
}

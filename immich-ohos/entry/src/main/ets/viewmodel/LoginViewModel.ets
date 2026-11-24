import { AuthApi } from '../service/AuthApi';
import { HttpClient, HttpError, immichHttp } from '../service/HttpClient';
import { SessionStore } from '../service/SessionStore';
import { normalizeApiBaseUrl } from '../common/UrlUtil';

/**
 * Login screen state and Immich sign-in flow.
 */
export class LoginViewModel {
  serverUrl: string = '';
  email: string = '';
  password: string = '';
  busy: boolean = false;
  errorMessage: string = '';

  private http: HttpClient = immichHttp;
  private authApi: AuthApi = new AuthApi(immichHttp);

  async loadSavedServer(): Promise<void> {
    this.serverUrl = await SessionStore.getServerUrl();
    this.email = await SessionStore.getUserEmail();
  }

  async login(): Promise<boolean> {
    this.errorMessage = '';
    const url = this.serverUrl.trim();
    const email = this.email.trim();
    if (url.length === 0 || email.length === 0 || this.password.length === 0) {
      this.errorMessage = 'Server URL, email, and password are required';
      return false;
    }

    this.busy = true;
    try {
      this.http.setEndpoint(url, '');
      const ping = await this.authApi.ping();
      if (ping.res !== 'pong') {
        this.errorMessage = 'Server ping failed';
        return false;
      }

      const result = await this.authApi.login(email, this.password);
      const apiBase = normalizeApiBaseUrl(url);
      this.http.setEndpoint(apiBase, result.accessToken);
      await SessionStore.saveSession(
        apiBase,
        result.accessToken,
        result.userEmail,
        result.name ?? ''
      );
      this.password = '';
      return true;
    } catch (e) {
      if (e instanceof HttpError) {
        this.errorMessage = `Login failed (${e.code}): ${e.message}`;
      } else {
        this.errorMessage = `Login failed: ${String(e)}`;
      }
      return false;
    } finally {
      this.busy = false;
    }
  }
}

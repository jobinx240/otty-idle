import { AuthApi } from '../service/AuthApi';
import { ServerApi } from '../service/ServerApi';
import { HttpClient, HttpError, immichHttp } from '../service/HttpClient';
import { SessionStore } from '../service/SessionStore';
import { normalizeApiBaseUrl } from '../common/UrlUtil';
import { VersionGate } from '../common/VersionGate';

/**
 * Login screen state and Immich sign-in flow.
 */
export class LoginViewModel {
  serverUrl: string = '';
  email: string = '';
  password: string = '';
  useCustomCa: boolean = false;
  customCaPem: string = '';
  busy: boolean = false;
  errorMessage: string = '';
  warningMessage: string = '';

  private http: HttpClient = immichHttp;
  private authApi: AuthApi = new AuthApi(immichHttp);
  private serverApi: ServerApi = new ServerApi(immichHttp);

  async loadSavedServer(): Promise<void> {
    this.serverUrl = await SessionStore.getServerUrl();
    this.email = await SessionStore.getUserEmail();
    this.useCustomCa = await SessionStore.getUseCustomCa();
    this.customCaPem = await SessionStore.getCustomCaPem();
  }

  async login(): Promise<boolean> {
    this.errorMessage = '';
    this.warningMessage = '';
    const url = this.serverUrl.trim();
    const email = this.email.trim();
    if (url.length === 0 || email.length === 0 || this.password.length === 0) {
      this.errorMessage = 'Server URL, email, and password are required';
      return false;
    }
    if (this.useCustomCa && this.customCaPem.trim().length === 0) {
      this.errorMessage = 'Custom CA PEM is required when the TLS toggle is on';
      return false;
    }

    this.busy = true;
    try {
      await SessionStore.setCustomCa(this.useCustomCa, this.customCaPem.trim());
      this.http.setCustomCaPem(this.useCustomCa ? this.customCaPem.trim() : '');
      this.http.setEndpoint(url, '');

      const ping = await this.authApi.ping();
      if (ping.res !== 'pong') {
        this.errorMessage = 'Server ping failed';
        return false;
      }

      try {
        const ver = await this.serverApi.version();
        const gate = VersionGate.evaluate(ver);
        if (!gate.ok) {
          this.errorMessage = gate.warning;
          return false;
        }
        if (gate.warning.length > 0) {
          this.warningMessage = gate.warning;
        }
      } catch (_e) {
        this.warningMessage = 'Could not read server version; continuing login';
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

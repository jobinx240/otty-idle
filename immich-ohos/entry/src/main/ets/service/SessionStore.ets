import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Constants } from '../common/Constants';

/**
 * Persists Immich session, TLS CA override, and backup upload queue.
 */
export class SessionStore {
  private static prefs: preferences.Preferences | null = null;

  static async init(context: common.UIAbilityContext): Promise<void> {
    SessionStore.prefs = await preferences.getPreferences(context, Constants.PREFS_NAME);
  }

  private static requirePrefs(): preferences.Preferences {
    if (!SessionStore.prefs) {
      throw new Error('SessionStore not initialized');
    }
    return SessionStore.prefs;
  }

  static async getServerUrl(): Promise<string> {
    return (await SessionStore.requirePrefs().get(Constants.KEY_SERVER_URL, '')) as string;
  }

  static async getAccessToken(): Promise<string> {
    return (await SessionStore.requirePrefs().get(Constants.KEY_ACCESS_TOKEN, '')) as string;
  }

  static async getUserEmail(): Promise<string> {
    return (await SessionStore.requirePrefs().get(Constants.KEY_USER_EMAIL, '')) as string;
  }

  static async getUserName(): Promise<string> {
    return (await SessionStore.requirePrefs().get(Constants.KEY_USER_NAME, '')) as string;
  }

  static async getUseCustomCa(): Promise<boolean> {
    return (await SessionStore.requirePrefs().get(Constants.KEY_USE_CUSTOM_CA, false)) as boolean;
  }

  static async getCustomCaPem(): Promise<string> {
    return (await SessionStore.requirePrefs().get(Constants.KEY_CUSTOM_CA_PEM, '')) as string;
  }

  static async setCustomCa(useCustomCa: boolean, pem: string): Promise<void> {
    const prefs = SessionStore.requirePrefs();
    await prefs.put(Constants.KEY_USE_CUSTOM_CA, useCustomCa);
    await prefs.put(Constants.KEY_CUSTOM_CA_PEM, pem);
    await prefs.flush();
  }

  static async getUploadQueueJson(): Promise<string> {
    return (await SessionStore.requirePrefs().get(Constants.KEY_UPLOAD_QUEUE, '[]')) as string;
  }

  static async setUploadQueueJson(json: string): Promise<void> {
    const prefs = SessionStore.requirePrefs();
    await prefs.put(Constants.KEY_UPLOAD_QUEUE, json);
    await prefs.flush();
  }

  static async saveSession(
    serverUrl: string,
    accessToken: string,
    email: string,
    name: string
  ): Promise<void> {
    const prefs = SessionStore.requirePrefs();
    await prefs.put(Constants.KEY_SERVER_URL, serverUrl);
    await prefs.put(Constants.KEY_ACCESS_TOKEN, accessToken);
    await prefs.put(Constants.KEY_USER_EMAIL, email);
    await prefs.put(Constants.KEY_USER_NAME, name);
    await prefs.flush();
  }

  static async clear(): Promise<void> {
    const prefs = SessionStore.requirePrefs();
    await prefs.delete(Constants.KEY_ACCESS_TOKEN);
    await prefs.delete(Constants.KEY_USER_EMAIL);
    await prefs.delete(Constants.KEY_USER_NAME);
    await prefs.flush();
  }

  static async hasSession(): Promise<boolean> {
    const url = await SessionStore.getServerUrl();
    const token = await SessionStore.getAccessToken();
    return url.length > 0 && token.length > 0;
  }
}

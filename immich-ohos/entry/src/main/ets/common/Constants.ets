/**
 * Shared constants for the Immich HarmonyOS client.
 */
export class Constants {
  /** Immich HTTP API prefix under the server origin. */
  static readonly API_PREFIX: string = '/api';

  /** Preferences file name for session data. */
  static readonly PREFS_NAME: string = 'immich_session';

  static readonly KEY_SERVER_URL: string = 'serverUrl';
  static readonly KEY_ACCESS_TOKEN: string = 'accessToken';
  static readonly KEY_USER_EMAIL: string = 'userEmail';
  static readonly KEY_USER_NAME: string = 'userName';

  /**
   * Emulator → host Immich (QEMU user networking). Long-press the login title to apply.
   */
  static readonly DEBUG_SERVER_URL: string = 'http://10.0.2.2:2283';
  static readonly DEBUG_EMAIL: string = 'admin@local.test';
  static readonly DEBUG_PASSWORD: string = 'Admin12345';
}

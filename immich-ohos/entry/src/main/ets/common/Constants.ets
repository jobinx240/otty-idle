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
  /** When true, HttpClient sends SessionStore custom CA PEM as caData. */
  static readonly KEY_USE_CUSTOM_CA: string = 'useCustomCa';
  /** PEM text for a single custom CA (self-signed Immich HTTPS). */
  static readonly KEY_CUSTOM_CA_PEM: string = 'customCaPem';
  /** JSON array of pending LocalUploadItem snapshots for background resume. */
  static readonly KEY_UPLOAD_QUEUE: string = 'uploadQueue';

  /**
   * Immich server major compatibility window for this client build.
   * Login fails below MIN; above MAX shows a soft warning only.
   */
  static readonly MIN_SERVER_MAJOR: number = 1;
  static readonly MAX_SERVER_MAJOR: number = 3;

  /** App label shown next to version gate messages. */
  static readonly APP_VERSION_NAME: string = '0.1.0';

  /** WorkScheduler deferred upload work id. */
  static readonly UPLOAD_WORK_ID: number = 1001;

  /**
   * Emulator → host Immich (QEMU user networking). Long-press the login title to apply.
   */
  static readonly DEBUG_SERVER_URL: string = 'http://10.0.2.2:2283';
  static readonly DEBUG_EMAIL: string = 'admin@local.test';
  static readonly DEBUG_PASSWORD: string = 'Admin12345';
}

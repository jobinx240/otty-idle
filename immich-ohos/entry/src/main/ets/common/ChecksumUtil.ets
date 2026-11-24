import { util } from '@kit.ArkTS';
import { hash } from '@kit.CoreFileKit';

/**
 * Immich upload checksum helpers (SHA-1 digest as standard Base64).
 */
export class ChecksumUtil {
  /**
   * SHA-1 file digest encoded as Base64 (Immich x-immich-checksum format).
   * Returns empty string when the path cannot be hashed (e.g. picker content URI).
   */
  static async sha1Base64ForPath(path: string): Promise<string> {
    try {
      const hex = await hash.hash(path, 'sha1');
      return ChecksumUtil.hexToBase64(hex);
    } catch (_e) {
      return '';
    }
  }

  /** Convert uppercase/lowercase hex string to Base64. */
  static hexToBase64(hex: string): string {
    const clean = hex.replace(/\s+/g, '');
    if (clean.length === 0 || clean.length % 2 !== 0) {
      return '';
    }
    const bytes = new Uint8Array(clean.length / 2);
    for (let i = 0; i < bytes.length; i++) {
      const byteHex = clean.substring(i * 2, i * 2 + 2);
      bytes[i] = Number.parseInt(byteHex, 16);
    }
    const helper = new util.Base64Helper();
    return helper.encodeToStringSync(bytes);
  }
}

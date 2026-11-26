import { ServerVersionResponseDto } from '../model/PeopleModels';
import { Constants } from './Constants';

/** Result of comparing Immich server version to the app compatibility window. */
export class VersionGateResult {
  ok: boolean;
  warning: string;
  versionText: string;

  constructor(ok: boolean, warning: string, versionText: string) {
    this.ok = ok;
    this.warning = warning;
    this.versionText = versionText;
  }
}

/**
 * Soft/hard version gate for personal Immich clients.
 * Blocks login only when the server major is below the minimum.
 */
export class VersionGate {
  static evaluate(ver: ServerVersionResponseDto): VersionGateResult {
    const major = ver.major ?? 0;
    const minor = ver.minor ?? 0;
    const patch = ver.patch ?? 0;
    const text = `${major}.${minor}.${patch}`;

    if (major < Constants.MIN_SERVER_MAJOR) {
      return new VersionGateResult(
        false,
        `Server ${text} is too old. Need major >= ${Constants.MIN_SERVER_MAJOR}.`,
        text
      );
    }
    if (major > Constants.MAX_SERVER_MAJOR) {
      return new VersionGateResult(
        true,
        `Server ${text} is newer than this app (tested up to major ${Constants.MAX_SERVER_MAJOR}). Some features may break.`,
        text
      );
    }
    return new VersionGateResult(true, '', text);
  }
}

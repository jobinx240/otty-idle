import { TimelineApi } from '../service/TimelineApi';
import { AuthApi } from '../service/AuthApi';
import { HttpError, immichHttp } from '../service/HttpClient';
import { SessionStore } from '../service/SessionStore';
import { TimeBucketsResponseDto } from '../model/TimelineModels';

export class TimelineAssetCell {
  id: string;
  thumbUrl: string;

  constructor(id: string, thumbUrl: string) {
    this.id = id;
    this.thumbUrl = thumbUrl;
  }
}

/**
 * Timeline buckets + first-page asset ids for the grid.
 */
export class TimelineViewModel {
  userName: string = '';
  buckets: TimeBucketsResponseDto[] = [];
  assets: TimelineAssetCell[] = [];
  busy: boolean = false;
  errorMessage: string = '';

  private timelineApi: TimelineApi = new TimelineApi(immichHttp);
  private authApi: AuthApi = new AuthApi(immichHttp);

  async load(): Promise<void> {
    this.busy = true;
    this.errorMessage = '';
    try {
      await immichHttp.loadFromSession();
      this.userName = await SessionStore.getUserName();
      try {
        const me = await this.authApi.getMe();
        this.userName = me.name ?? this.userName;
      } catch (_ignore) {
        // Name from session is enough for MVP.
      }

      this.buckets = await this.timelineApi.getBuckets();
      this.assets = [];
      const maxAssets = 120;
      const limitBuckets = Math.min(this.buckets.length, 12);
      for (let i = 0; i < limitBuckets && this.assets.length < maxAssets; i++) {
        const bucket = this.buckets[i];
        const detail = await this.timelineApi.getBucket(bucket.timeBucket);
        const ids = detail.id ?? [];
        for (let j = 0; j < ids.length && this.assets.length < maxAssets; j++) {
          const id = ids[j];
          this.assets.push(new TimelineAssetCell(id, immichHttp.thumbnailUrl(id)));
        }
      }
    } catch (e) {
      if (e instanceof HttpError) {
        this.errorMessage = `Timeline error (${e.code}): ${e.message}`;
      } else {
        this.errorMessage = `Timeline error: ${String(e)}`;
      }
    } finally {
      this.busy = false;
    }
  }

  async logout(): Promise<void> {
    try {
      await this.authApi.logout();
    } catch (_ignore) {
      // Always clear local session.
    }
    await SessionStore.clear();
  }
}
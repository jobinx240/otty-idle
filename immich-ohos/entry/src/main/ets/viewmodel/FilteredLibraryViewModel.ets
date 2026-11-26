import { TimelineApi, TimelineFilter } from '../service/TimelineApi';
import { TrashApi } from '../service/TrashApi';
import { AssetApi } from '../service/AssetApi';
import { HttpError, immichHttp } from '../service/HttpClient';
import { TimelineAssetCell } from './TimelineViewModel';

/**
 * Trash or archive library grid backed by filtered timeline buckets.
 */
export class FilteredLibraryViewModel {
  assets: TimelineAssetCell[] = [];
  busy: boolean = false;
  errorMessage: string = '';
  actionMessage: string = '';

  private timelineApi: TimelineApi = new TimelineApi(immichHttp);
  private trashApi: TrashApi = new TrashApi(immichHttp);
  private assetApi: AssetApi = new AssetApi(immichHttp);
  private filter: TimelineFilter = new TimelineFilter();

  /** Load trash (isTrashed=true) assets. */
  async loadTrash(): Promise<void> {
    this.filter = TimelineFilter.trash();
    await this.load();
  }

  /** Load archived (visibility=archive) assets. */
  async loadArchive(): Promise<void> {
    this.filter = TimelineFilter.archive();
    await this.load();
  }

  private async load(): Promise<void> {
    this.busy = true;
    this.errorMessage = '';
    this.assets = [];
    try {
      await immichHttp.loadFromSession();
      const buckets = await this.timelineApi.getBuckets(this.filter);
      const maxAssets = 120;
      const limitBuckets = Math.min(buckets.length, 12);
      for (let i = 0; i < limitBuckets && this.assets.length < maxAssets; i++) {
        const detail = await this.timelineApi.getBucket(buckets[i].timeBucket, this.filter);
        const ids = detail.id ?? [];
        const images = detail.isImage ?? [];
        const favorites = detail.isFavorite ?? [];
        for (let j = 0; j < ids.length && this.assets.length < maxAssets; j++) {
          const id = ids[j];
          const isImage = images.length > j ? images[j] : true;
          const isFavorite = favorites.length > j ? favorites[j] : false;
          this.assets.push(new TimelineAssetCell(id, immichHttp.thumbnailUrl(id), isImage, isFavorite));
        }
      }
    } catch (e) {
      this.errorMessage = e instanceof HttpError
        ? `Library error (${e.code}): ${e.message}`
        : `Library error: ${String(e)}`;
    } finally {
      this.busy = false;
    }
  }

  async restoreAsset(id: string): Promise<void> {
    this.actionMessage = '';
    try {
      await this.trashApi.restoreAssets([id]);
      this.assets = this.assets.filter((a: TimelineAssetCell) => a.id !== id);
      this.actionMessage = 'Restored';
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Restore failed (${e.code})` : String(e);
    }
  }

  async restoreAll(): Promise<void> {
    this.actionMessage = '';
    try {
      await this.trashApi.restoreAll();
      this.assets = [];
      this.actionMessage = 'Trash restored';
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Restore all failed (${e.code})` : String(e);
    }
  }

  async emptyTrash(): Promise<void> {
    this.actionMessage = '';
    try {
      await this.trashApi.emptyTrash();
      this.assets = [];
      this.actionMessage = 'Trash emptied';
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Empty failed (${e.code})` : String(e);
    }
  }

  async unarchiveAsset(id: string): Promise<void> {
    this.actionMessage = '';
    try {
      await this.assetApi.unarchive(id);
      this.assets = this.assets.filter((a: TimelineAssetCell) => a.id !== id);
      this.actionMessage = 'Unarchived';
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Unarchive failed (${e.code})` : String(e);
    }
  }
}

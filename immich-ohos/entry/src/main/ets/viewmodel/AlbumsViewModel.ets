import { AlbumApi } from '../service/AlbumApi';
import { AlbumListItem } from '../model/AlbumModels';
import { HttpError, immichHttp } from '../service/HttpClient';
import { TimelineAssetCell } from './TimelineViewModel';

/**
 * Album list + album-scoped asset grid state.
 */
export class AlbumsViewModel {
  albums: AlbumListItem[] = [];
  assets: TimelineAssetCell[] = [];
  albumTitle: string = '';
  busy: boolean = false;
  errorMessage: string = '';

  private albumApi: AlbumApi = new AlbumApi(immichHttp);

  async loadList(): Promise<void> {
    this.busy = true;
    this.errorMessage = '';
    try {
      await immichHttp.loadFromSession();
      const all = await this.albumApi.listAlbums();
      this.albums = all.slice().sort((a: AlbumListItem, b: AlbumListItem) => {
        return (b.assetCount || 0) - (a.assetCount || 0);
      });
    } catch (e) {
      if (e instanceof HttpError) {
        this.errorMessage = `Albums error (${e.code}): ${e.message}`;
      } else {
        this.errorMessage = `Albums error: ${String(e)}`;
      }
    } finally {
      this.busy = false;
    }
  }

  /** Create an empty album and refresh the list. */
  async createAlbum(albumName: string): Promise<AlbumListItem | undefined> {
    const name = albumName.trim();
    if (name.length === 0) {
      this.errorMessage = 'Enter an album name';
      return undefined;
    }
    this.busy = true;
    this.errorMessage = '';
    try {
      await immichHttp.loadFromSession();
      const created = await this.albumApi.createAlbum(name);
      await this.loadList();
      return created;
    } catch (e) {
      if (e instanceof HttpError) {
        this.errorMessage = `Create album (${e.code}): ${e.message}`;
      } else {
        this.errorMessage = `Create album: ${String(e)}`;
      }
      this.busy = false;
      return undefined;
    }
  }

  async loadAlbumAssets(albumId: string, albumName: string): Promise<void> {
    this.busy = true;
    this.errorMessage = '';
    this.albumTitle = albumName;
    this.assets = [];
    try {
      await immichHttp.loadFromSession();
      const buckets = await this.albumApi.getAlbumBuckets(albumId);
      const maxAssets = 120;
      const limitBuckets = Math.min(buckets.length, 12);
      for (let i = 0; i < limitBuckets && this.assets.length < maxAssets; i++) {
        const detail = await this.albumApi.getAlbumBucket(albumId, buckets[i].timeBucket);
        const ids = detail.id ?? [];
        for (let j = 0; j < ids.length && this.assets.length < maxAssets; j++) {
          const id = ids[j];
          this.assets.push(new TimelineAssetCell(id, immichHttp.thumbnailUrl(id)));
        }
      }
    } catch (e) {
      if (e instanceof HttpError) {
        this.errorMessage = `Album detail error (${e.code}): ${e.message}`;
      } else {
        this.errorMessage = `Album detail error: ${String(e)}`;
      }
    } finally {
      this.busy = false;
    }
  }
}

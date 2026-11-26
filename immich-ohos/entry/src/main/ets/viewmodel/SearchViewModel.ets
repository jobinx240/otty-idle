import { SearchApi } from '../service/SearchApi';
import { SearchAssetItem } from '../model/AlbumModels';
import { HttpError, immichHttp } from '../service/HttpClient';
import { TimelineAssetCell } from './TimelineViewModel';

/**
 * Metadata / smart / favorites search state.
 */
export class SearchViewModel {
  query: string = '';
  assets: TimelineAssetCell[] = [];
  busy: boolean = false;
  errorMessage: string = '';
  modeLabel: string = 'metadata';

  private searchApi: SearchApi = new SearchApi(immichHttp);

  private applyItems(items: SearchAssetItem[]): void {
    this.assets = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const isImage = (item.type ?? 'IMAGE').toUpperCase() !== 'VIDEO';
      this.assets.push(new TimelineAssetCell(item.id, immichHttp.thumbnailUrl(item.id), isImage, false));
    }
  }

  async search(): Promise<void> {
    const q = this.query.trim();
    if (q.length === 0) {
      this.errorMessage = 'Enter a search query';
      return;
    }
    this.busy = true;
    this.errorMessage = '';
    this.assets = [];
    this.modeLabel = 'metadata';
    try {
      await immichHttp.loadFromSession();
      const result = await this.searchApi.searchMetadata(q, 60);
      this.applyItems(result.assets?.items ?? []);
    } catch (e) {
      this.errorMessage = e instanceof HttpError
        ? `Search error (${e.code}): ${e.message}`
        : `Search error: ${String(e)}`;
    } finally {
      this.busy = false;
    }
  }

  async searchSmart(): Promise<void> {
    const q = this.query.trim();
    if (q.length === 0) {
      this.errorMessage = 'Enter a smart-search prompt';
      return;
    }
    this.busy = true;
    this.errorMessage = '';
    this.assets = [];
    this.modeLabel = 'smart';
    try {
      await immichHttp.loadFromSession();
      const result = await this.searchApi.searchSmart(q, 60);
      this.applyItems(result.assets?.items ?? []);
    } catch (e) {
      this.errorMessage = e instanceof HttpError
        ? `Smart search (${e.code}): ${e.message}`
        : `Smart search: ${String(e)}`;
    } finally {
      this.busy = false;
    }
  }

  async loadFavorites(): Promise<void> {
    this.busy = true;
    this.errorMessage = '';
    this.assets = [];
    this.modeLabel = 'favorites';
    this.query = '';
    try {
      await immichHttp.loadFromSession();
      const result = await this.searchApi.searchFavorites(120);
      this.applyItems(result.assets?.items ?? []);
      if (this.assets.length === 0) {
        this.errorMessage = 'No favorites yet';
      }
    } catch (e) {
      this.errorMessage = e instanceof HttpError
        ? `Favorites (${e.code}): ${e.message}`
        : `Favorites: ${String(e)}`;
    } finally {
      this.busy = false;
    }
  }

  async loadPerson(personId: string): Promise<void> {
    this.busy = true;
    this.errorMessage = '';
    this.assets = [];
    this.modeLabel = 'person';
    try {
      await immichHttp.loadFromSession();
      const result = await this.searchApi.searchByPerson(personId, 120);
      this.applyItems(result.assets?.items ?? []);
    } catch (e) {
      this.errorMessage = e instanceof HttpError
        ? `Person assets (${e.code}): ${e.message}`
        : `Person assets: ${String(e)}`;
    } finally {
      this.busy = false;
    }
  }
}

import { SearchApi } from '../service/SearchApi';
import { HttpError, immichHttp } from '../service/HttpClient';
import { TimelineAssetCell } from './TimelineViewModel';

/**
 * Metadata search state for the search page.
 */
export class SearchViewModel {
  query: string = '';
  assets: TimelineAssetCell[] = [];
  busy: boolean = false;
  errorMessage: string = '';

  private searchApi: SearchApi = new SearchApi(immichHttp);

  async search(): Promise<void> {
    const q = this.query.trim();
    if (q.length === 0) {
      this.errorMessage = 'Enter a search query';
      return;
    }
    this.busy = true;
    this.errorMessage = '';
    this.assets = [];
    try {
      await immichHttp.loadFromSession();
      const result = await this.searchApi.searchMetadata(q, 60);
      const items = result.assets?.items ?? [];
      for (let i = 0; i < items.length; i++) {
        const id = items[i].id;
        this.assets.push(new TimelineAssetCell(id, immichHttp.thumbnailUrl(id)));
      }
    } catch (e) {
      if (e instanceof HttpError) {
        this.errorMessage = `Search error (${e.code}): ${e.message}`;
      } else {
        this.errorMessage = `Search error: ${String(e)}`;
      }
    } finally {
      this.busy = false;
    }
  }
}

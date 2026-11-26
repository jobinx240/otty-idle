import { SessionStore } from './SessionStore';
import { LocalUploadItem } from '../model/AssetModels';

interface UploadQueueSnapshot {
  uri: string;
  fileName: string;
  deviceAssetId: string;
  status: string;
}

/**
 * Persist / restore pending backup uploads across process restarts.
 */
export class UploadQueueStore {
  static async savePending(items: LocalUploadItem[]): Promise<void> {
    const pending: UploadQueueSnapshot[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (item.status === 'pending' || item.status === 'uploading' || item.status === 'error') {
        pending.push({
          uri: item.uri,
          fileName: item.fileName,
          deviceAssetId: item.deviceAssetId,
          status: 'pending'
        });
      }
    }
    await SessionStore.setUploadQueueJson(JSON.stringify(pending));
  }

  static async loadPending(): Promise<LocalUploadItem[]> {
    const raw = await SessionStore.getUploadQueueJson();
    if (raw.length === 0) {
      return [];
    }
    try {
      const parsed = JSON.parse(raw) as UploadQueueSnapshot[];
      const items: LocalUploadItem[] = [];
      for (let i = 0; i < parsed.length; i++) {
        const row = parsed[i];
        if (!row.uri || !row.fileName || !row.deviceAssetId) {
          continue;
        }
        items.push(new LocalUploadItem(row.uri, row.fileName, row.deviceAssetId));
      }
      return items;
    } catch (_e) {
      return [];
    }
  }

  static async clear(): Promise<void> {
    await SessionStore.setUploadQueueJson('[]');
  }
}

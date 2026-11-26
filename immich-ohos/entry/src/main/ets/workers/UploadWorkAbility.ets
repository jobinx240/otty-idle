import { WorkSchedulerExtensionAbility, workScheduler } from '@kit.BackgroundTasksKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { Constants } from '../common/Constants';
import { normalizeApiBaseUrl } from '../common/UrlUtil';
import { HttpClient } from '../service/HttpClient';
import { AssetApi } from '../service/AssetApi';

const DOMAIN = 0x3201;

interface UploadQueueSnapshot {
  uri: string;
  fileName: string;
  deviceAssetId: string;
  status: string;
}

/**
 * Deferred WorkScheduler entry that drains the persisted Immich upload queue.
 */
export default class UploadWorkAbility extends WorkSchedulerExtensionAbility {
  onWorkStart(workInfo: workScheduler.WorkInfo): void {
    hilog.info(DOMAIN, 'ImmichOH', 'UploadWork onWorkStart id=%{public}d', workInfo.workId);
    this.runQueue().catch((e: Error) => {
      hilog.error(DOMAIN, 'ImmichOH', 'UploadWork failed: %{public}s', String(e));
    });
  }

  onWorkStop(workInfo: workScheduler.WorkInfo): void {
    hilog.info(DOMAIN, 'ImmichOH', 'UploadWork onWorkStop id=%{public}d', workInfo.workId);
  }

  private async runQueue(): Promise<void> {
    const prefs = await preferences.getPreferences(this.context, Constants.PREFS_NAME);
    const serverUrl = (await prefs.get(Constants.KEY_SERVER_URL, '')) as string;
    const token = (await prefs.get(Constants.KEY_ACCESS_TOKEN, '')) as string;
    const queueRaw = (await prefs.get(Constants.KEY_UPLOAD_QUEUE, '[]')) as string;
    if (serverUrl.length === 0 || token.length === 0) {
      return;
    }

    let rows: UploadQueueSnapshot[] = [];
    try {
      rows = JSON.parse(queueRaw) as UploadQueueSnapshot[];
    } catch (_e) {
      return;
    }
    if (rows.length === 0) {
      return;
    }

    const http = new HttpClient();
    http.setEndpoint(normalizeApiBaseUrl(serverUrl), token);
    const useCa = (await prefs.get(Constants.KEY_USE_CUSTOM_CA, false)) as boolean;
    const pem = (await prefs.get(Constants.KEY_CUSTOM_CA_PEM, '')) as string;
    if (useCa && pem.length > 0) {
      http.setCustomCaPem(pem);
    }

    const assetApi = new AssetApi(http);
    const remaining: UploadQueueSnapshot[] = [];
    const nowIso = new Date().toISOString();
    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      try {
        await assetApi.uploadFile(row.uri, row.fileName, row.deviceAssetId, nowIso, nowIso);
      } catch (e) {
        hilog.warn(DOMAIN, 'ImmichOH', 'Upload item failed: %{public}s', String(e));
        remaining.push(row);
      }
    }
    await prefs.put(Constants.KEY_UPLOAD_QUEUE, JSON.stringify(remaining));
    await prefs.flush();
  }
}

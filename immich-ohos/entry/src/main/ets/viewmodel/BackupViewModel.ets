import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AssetApi } from '../service/AssetApi';
import { LocalUploadItem } from '../model/AssetModels';
import { HttpError, immichHttp } from '../service/HttpClient';

/**
 * Photo picker + sequential Immich upload queue for personal backup.
 */
export class BackupViewModel {
  items: LocalUploadItem[] = [];
  busy: boolean = false;
  errorMessage: string = '';
  doneCount: number = 0;

  private assetApi: AssetApi = new AssetApi(immichHttp);

  async pickImages(): Promise<void> {
    this.errorMessage = '';
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 30
      });
      const uris = result.photoUris ?? [];
      const next: LocalUploadItem[] = [];
      for (let i = 0; i < uris.length; i++) {
        const uri = uris[i];
        const fileName = BackupViewModel.fileNameFromUri(uri);
        const deviceAssetId = AssetApi.deviceAssetIdFromUri(uri);
        next.push(new LocalUploadItem(uri, fileName, deviceAssetId));
      }
      this.items = next;
      this.doneCount = 0;
    } catch (e) {
      this.errorMessage = `Picker failed: ${String(e)}`;
    }
  }

  /**
   * Queue the bundled debug JPEG (rawfile) for emulator / CI upload checks.
   * Long-press the Backup title to invoke.
   */
  async queueDebugRawfile(context: common.UIAbilityContext): Promise<void> {
    this.errorMessage = '';
    try {
      const raw = await context.resourceManager.getRawFileContent('debug_upload.jpg');
      const fileName = `debug_upload_${Date.now()}.jpg`;
      const path = `${context.cacheDir}/${fileName}`;
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, raw.buffer);
      fs.closeSync(file);
      const deviceAssetId = `ohos_debug_${Date.now()}`;
      this.items = [new LocalUploadItem(path, fileName, deviceAssetId)];
      this.doneCount = 0;
    } catch (e) {
      this.errorMessage = `Debug queue failed: ${String(e)}`;
    }
  }

  async uploadAll(onProgress?: () => void): Promise<void> {
    if (this.items.length === 0) {
      this.errorMessage = 'Pick photos first';
      return;
    }
    this.busy = true;
    this.errorMessage = '';
    this.doneCount = 0;
    await immichHttp.loadFromSession();

    const nowIso = new Date().toISOString();
    for (let i = 0; i < this.items.length; i++) {
      const item = this.items[i];
      item.status = 'uploading';
      item.message = '';
      this.items = this.items.slice();
      if (onProgress) {
        onProgress();
      }
      try {
        const response = await this.assetApi.uploadFile(
          item.uri,
          item.fileName,
          item.deviceAssetId,
          nowIso,
          nowIso
        );
        item.remoteId = response.id;
        if (response.status === 'duplicate') {
          item.status = 'duplicate';
          item.message = 'Already on server';
        } else {
          item.status = 'done';
          item.message = 'Uploaded';
        }
        this.doneCount += 1;
      } catch (e) {
        item.status = 'error';
        if (e instanceof HttpError) {
          item.message = `HTTP ${e.code}: ${e.message}`;
        } else {
          item.message = String(e);
        }
      }
      this.items = this.items.slice();
      if (onProgress) {
        onProgress();
      }
    }
    this.busy = false;
    if (onProgress) {
      onProgress();
    }
  }

  private static fileNameFromUri(uri: string): string {
    const parts = uri.split('/');
    const last = parts.length > 0 ? parts[parts.length - 1] : '';
    if (last.length > 0 && last.indexOf('.') >= 0) {
      return last;
    }
    return `immich_${Date.now()}.jpg`;
  }
}

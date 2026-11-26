import { workScheduler } from '@kit.BackgroundTasksKit';
import { Constants } from '../common/Constants';

/**
 * Registers a deferred WorkScheduler job to resume pending Immich uploads.
 */
export class BackupScheduler {
  static schedule(): string {
    try {
      const info: workScheduler.WorkInfo = {
        workId: Constants.UPLOAD_WORK_ID,
        bundleName: 'app.personal.immich.ohos',
        abilityName: 'UploadWorkAbility',
        isPersisted: true,
        networkType: workScheduler.NetworkType.NETWORK_TYPE_ANY
      };
      workScheduler.startWork(info);
      return 'Background upload scheduled';
    } catch (e) {
      return `Background schedule failed: ${String(e)}`;
    }
  }

  static cancel(): string {
    try {
      const info: workScheduler.WorkInfo = {
        workId: Constants.UPLOAD_WORK_ID,
        bundleName: 'app.personal.immich.ohos',
        abilityName: 'UploadWorkAbility'
      };
      workScheduler.stopWork(info, true);
      return 'Background upload cancelled';
    } catch (e) {
      return `Cancel failed: ${String(e)}`;
    }
  }
}
